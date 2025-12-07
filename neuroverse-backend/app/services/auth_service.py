from datetime import datetime, timedelta
from typing import Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from fastapi import HTTPException, status

# CORRECT IMPORT PATH based on your folder structure
from app.models.user import User, OTPCode, PasswordResetToken, UserStatusEnum
from app.schemas.user import UserRegister, TokenResponse
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_otp,
    generate_reset_token,
)
from app.core.config import settings


class AuthService:
    """Service for handling authentication operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        result = await self.db.execute(
            select(User).where(User.email == email.lower())
        )
        return result.scalar_one_or_none()
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def register_user(self, user_data: UserRegister) -> Tuple[User, str]:
        """Register a new user and generate OTP."""
        # Check if user already exists
        existing_user = await self.get_user_by_email(user_data.email)
        if existing_user:
            if existing_user.is_email_verified:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
            # Delete unverified user to allow re-registration
            await self.db.delete(existing_user)
            await self.db.flush()
        
        # Create new user
        user = User(
            email=user_data.email.lower(),
            password_hash=get_password_hash(user_data.password),
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            phone=user_data.phone,
            date_of_birth=user_data.date_of_birth,
            gender=user_data.gender,
            status=UserStatusEnum.PENDING_VERIFICATION,
        )
        
        self.db.add(user)
        await self.db.flush()
        
        # Generate and save OTP
        otp_code = await self._create_otp(user.id, "signup")
        
        return user, otp_code
    
    async def login_user(self, email: str, password: str) -> TokenResponse:
        """Authenticate user and return tokens."""
        user = await self.get_user_by_email(email)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Check if account is locked
        if user.locked_until and user.locked_until > datetime.utcnow():
            remaining_time = (user.locked_until - datetime.utcnow()).seconds // 60
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Account locked. Try again in {remaining_time} minutes."
            )
        
        # Verify password
        if not verify_password(password, user.password_hash):
            # Increment failed attempts
            user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
            
            # Lock account after 5 failed attempts
            if user.failed_login_attempts >= 5:
                user.locked_until = datetime.utcnow() + timedelta(minutes=30)
            
            await self.db.flush()
            
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Check if email is verified
        if not user.is_email_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email not verified. Please verify your email first."
            )
        
        # Reset failed attempts on successful login
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.utcnow()
        await self.db.flush()
        
        # Generate tokens
        return self._create_tokens(user.id)
    
    async def verify_otp(self, email: str, otp: str, purpose: str) -> User:
        """Verify OTP code."""
        user = await self.get_user_by_email(email)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Find valid OTP
        result = await self.db.execute(
            select(OTPCode).where(
                and_(
                    OTPCode.user_id == user.id,
                    OTPCode.code == otp,
                    OTPCode.purpose == purpose,
                    OTPCode.is_used == False,
                    OTPCode.expires_at > datetime.utcnow()
                )
            )
        )
        otp_record = result.scalar_one_or_none()
        
        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP"
            )
        
        # Mark OTP as used
        otp_record.is_used = True
        
        # If signup verification, activate user
        if purpose == "signup":
            user.is_email_verified = True
            user.status = UserStatusEnum.ACTIVE
        
        await self.db.flush()
        
        return user
    
    async def resend_otp(self, email: str, purpose: str) -> str:
        """Resend OTP code."""
        user = await self.get_user_by_email(email)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Invalidate old OTPs
        result = await self.db.execute(
            select(OTPCode).where(
                and_(
                    OTPCode.user_id == user.id,
                    OTPCode.purpose == purpose,
                    OTPCode.is_used == False
                )
            )
        )
        old_otps = result.scalars().all()
        for otp in old_otps:
            otp.is_used = True
        
        # Generate new OTP
        otp_code = await self._create_otp(user.id, purpose)
        
        return otp_code
    
    async def forgot_password(self, email: str) -> Optional[str]:
        """Generate password reset token."""
        user = await self.get_user_by_email(email)
        
        if not user:
            # Don't reveal if email exists
            return None
        
        # Generate reset token
        token = generate_reset_token()
        expires_at = datetime.utcnow() + timedelta(hours=1)
        
        reset_token = PasswordResetToken(
            user_id=user.id,
            token=token,
            expires_at=expires_at
        )
        
        self.db.add(reset_token)
        await self.db.flush()
        
        return token
    
    async def reset_password(self, token: str, new_password: str) -> User:
        """Reset password using token."""
        result = await self.db.execute(
            select(PasswordResetToken).where(
                and_(
                    PasswordResetToken.token == token,
                    PasswordResetToken.is_used == False,
                    PasswordResetToken.expires_at > datetime.utcnow()
                )
            )
        )
        reset_token = result.scalar_one_or_none()
        
        if not reset_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )
        
        # Get user
        user = await self.get_user_by_id(reset_token.user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update password
        user.password_hash = get_password_hash(new_password)
        reset_token.is_used = True
        
        await self.db.flush()
        
        return user
    
    async def change_password(
        self,
        user_id: str,
        current_password: str,
        new_password: str
    ) -> User:
        """Change user password."""
        user = await self.get_user_by_id(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Verify current password
        if not verify_password(current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect"
            )
        
        # Update password
        user.password_hash = get_password_hash(new_password)
        await self.db.flush()
        
        return user
    
    async def refresh_tokens(self, refresh_token: str) -> TokenResponse:
        """Refresh access token using refresh token."""
        payload = decode_token(refresh_token)
        
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        user_id = payload.get("sub")
        user = await self.get_user_by_id(user_id)
        
        if not user or user.status != UserStatusEnum.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        return self._create_tokens(user_id)
    
    async def _create_otp(self, user_id: str, purpose: str) -> str:
        """Create and save OTP code."""
        otp_code = generate_otp()
        expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
        
        otp = OTPCode(
            user_id=user_id,
            code=otp_code,
            purpose=purpose,
            expires_at=expires_at
        )
        
        self.db.add(otp)
        await self.db.flush()
        
        return otp_code
    
    def _create_tokens(self, user_id: str) -> TokenResponse:
        """Create access and refresh tokens."""
        access_token = create_access_token(data={"sub": user_id})
        refresh_token = create_refresh_token(data={"sub": user_id})
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )