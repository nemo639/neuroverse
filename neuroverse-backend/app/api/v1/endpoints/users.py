from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.services.user_service import UserService
from app.schemas.user import (
    UserUpdate,
    UserPreferencesUpdate,
    UserProfileResponse,
    MessageResponse
)
from app.core.security import get_current_user_id

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_current_user_profile(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get current user's profile.
    """
    user_service = UserService(db)
    return await user_service.get_user_profile(user_id)


@router.patch("/me", response_model=UserProfileResponse)
async def update_profile(
    update_data: UserUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update current user's profile.
    
    Only first_name, last_name, phone, and location can be updated.
    """
    user_service = UserService(db)
    user = await user_service.update_user_profile(user_id, update_data)
    return await user_service.get_user_profile(user_id)


@router.patch("/me/preferences", response_model=MessageResponse)
async def update_preferences(
    preferences: UserPreferencesUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update user preferences (notifications, research participation, etc.)
    """
    user_service = UserService(db)
    await user_service.update_user_preferences(user_id, preferences)
    
    return MessageResponse(
        message="Preferences updated successfully.",
        success=True
    )


@router.post("/me/photo", response_model=MessageResponse)
async def upload_profile_photo(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload profile photo.
    
    Accepted formats: JPEG, PNG, WebP
    Max size: 10MB
    """
    user_service = UserService(db)
    photo_url = await user_service.upload_profile_photo(user_id, file)
    
    return MessageResponse(
        message=f"Profile photo uploaded successfully. URL: {photo_url}",
        success=True
    )


@router.delete("/me/photo", response_model=MessageResponse)
async def delete_profile_photo(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete profile photo.
    """
    user_service = UserService(db)
    await user_service.delete_profile_photo(user_id)
    
    return MessageResponse(
        message="Profile photo deleted successfully.",
        success=True
    )


@router.delete("/me", response_model=MessageResponse)
async def delete_account(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete user account.
    
    This action is irreversible and deletes all user data.
    """
    user_service = UserService(db)
    await user_service.delete_user_account(user_id)
    
    return MessageResponse(
        message="Account deleted successfully.",
        success=True
    )
