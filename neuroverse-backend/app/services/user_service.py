from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status, UploadFile
import os
import uuid
import aiofiles

from app.models.user import User
from app.schemas.user import UserUpdate, UserPreferencesUpdate, UserProfileResponse
from app.core.config import settings


class UserService:
    """Service for handling user operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_user_profile(self, user_id: str) -> UserProfileResponse:
        """Get user profile."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return UserProfileResponse(
            id=user.id,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
            full_name=user.full_name,
            phone=user.phone,
            date_of_birth=user.date_of_birth,
            gender=user.gender.value if user.gender else None,
            location=user.location,
            profile_photo=user.profile_photo,
            is_email_verified=user.is_email_verified,
            is_premium=user.is_premium,
            member_since=user.created_at
        )
    
    async def update_user_profile(
        self,
        user_id: str,
        update_data: UserUpdate
    ) -> User:
        """Update user profile."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update only provided fields
        update_dict = update_data.model_dump(exclude_unset=True)
        
        for field, value in update_dict.items():
            if value is not None:
                setattr(user, field, value)
        
        await self.db.flush()
        
        return user
    
    async def update_user_preferences(
        self,
        user_id: str,
        preferences: UserPreferencesUpdate
    ) -> User:
        """Update user preferences."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update only provided fields
        if preferences.notifications_enabled is not None:
            user.notifications_enabled = preferences.notifications_enabled
        if preferences.email_notifications is not None:
            user.email_notifications = preferences.email_notifications
        if preferences.research_participation is not None:
            user.research_participation = preferences.research_participation
        
        await self.db.flush()
        
        return user
    
    async def upload_profile_photo(
        self,
        user_id: str,
        file: UploadFile
    ) -> str:
        """Upload user profile photo."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Validate file type
        if file.content_type not in settings.ALLOWED_IMAGE_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid file type. Allowed: JPEG, PNG, WebP"
            )
        
        # Check file size
        content = await file.read()
        if len(content) > settings.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Max size: {settings.MAX_FILE_SIZE // (1024*1024)}MB"
            )
        
        # Create upload directory if not exists
        upload_dir = os.path.join(settings.UPLOAD_DIR, "profiles")
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate unique filename
        ext = file.filename.split(".")[-1] if file.filename else "jpg"
        filename = f"{user_id}_{uuid.uuid4().hex[:8]}.{ext}"
        filepath = os.path.join(upload_dir, filename)
        
        # Delete old photo if exists
        if user.profile_photo:
            old_path = user.profile_photo.replace("/uploads/", f"{settings.UPLOAD_DIR}/")
            if os.path.exists(old_path):
                os.remove(old_path)
        
        # Save new photo
        async with aiofiles.open(filepath, "wb") as f:
            await f.write(content)
        
        # Update user profile
        user.profile_photo = f"/uploads/profiles/{filename}"
        await self.db.flush()
        
        return user.profile_photo
    
    async def delete_profile_photo(self, user_id: str) -> None:
        """Delete user profile photo."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        if user.profile_photo:
            # Delete file
            filepath = user.profile_photo.replace("/uploads/", f"{settings.UPLOAD_DIR}/")
            if os.path.exists(filepath):
                os.remove(filepath)
            
            user.profile_photo = None
            await self.db.flush()
    
    async def delete_user_account(self, user_id: str) -> None:
        """Delete user account and all associated data."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Delete profile photo
        if user.profile_photo:
            filepath = user.profile_photo.replace("/uploads/", f"{settings.UPLOAD_DIR}/")
            if os.path.exists(filepath):
                os.remove(filepath)
        
        # Delete user (cascades to related data)
        await self.db.delete(user)
        await self.db.flush()
