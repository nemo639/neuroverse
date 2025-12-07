from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.services.auth_service import AuthService
from app.schemas.user import (
    UserRegister,
    UserLogin,
    TokenResponse,
    RefreshTokenRequest,
    OTPVerify,
    OTPResend,
    ForgotPassword,
    ResetPassword,
    ChangePassword,
    MessageResponse,
    UserResponse
)
from app.core.security import get_current_user_id

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user.
    
    Returns success message and sends OTP to email.
    """
    auth_service = AuthService(db)
    user, otp_code = await auth_service.register_user(user_data)
    
    # TODO: Send OTP via email
    # For development, return OTP in response (remove in production)
    
    return MessageResponse(
        message=f"Registration successful. Please verify your email. OTP: {otp_code}",
        success=True
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """
    Login with email and password.
    
    Returns access and refresh tokens.
    """
    auth_service = AuthService(db)
    return await auth_service.login_user(
        credentials.email,
        credentials.password
    )


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(
    otp_data: OTPVerify,
    db: AsyncSession = Depends(get_db)
):
    """
    Verify OTP code.
    
    For signup verification, returns tokens on success.
    """
    auth_service = AuthService(db)
    user = await auth_service.verify_otp(
        otp_data.email,
        otp_data.otp,
        otp_data.purpose
    )
    
    # Return tokens for signup verification
    if otp_data.purpose == "signup":
        return auth_service._create_tokens(user.id)
    
    # For other purposes, just return success
    return auth_service._create_tokens(user.id)


@router.post("/resend-otp", response_model=MessageResponse)
async def resend_otp(
    data: OTPResend,
    db: AsyncSession = Depends(get_db)
):
    """
    Resend OTP code.
    """
    auth_service = AuthService(db)
    otp_code = await auth_service.resend_otp(data.email, data.purpose)
    
    # TODO: Send OTP via email
    # For development, return OTP in response
    
    return MessageResponse(
        message=f"OTP sent successfully. OTP: {otp_code}",
        success=True
    )


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(
    data: ForgotPassword,
    db: AsyncSession = Depends(get_db)
):
    """
    Request password reset.
    
    Sends reset link to email.
    """
    auth_service = AuthService(db)
    token = await auth_service.forgot_password(data.email)
    
    # Always return success (don't reveal if email exists)
    # TODO: Send email with reset link
    
    if token:
        # For development, return token (remove in production)
        return MessageResponse(
            message=f"Password reset link sent. Token: {token}",
            success=True
        )
    
    return MessageResponse(
        message="If the email exists, a password reset link has been sent.",
        success=True
    )


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(
    data: ResetPassword,
    db: AsyncSession = Depends(get_db)
):
    """
    Reset password using token.
    """
    auth_service = AuthService(db)
    await auth_service.reset_password(data.token, data.new_password)
    
    return MessageResponse(
        message="Password reset successful. You can now login.",
        success=True
    )


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    data: ChangePassword,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Change password (requires authentication).
    """
    auth_service = AuthService(db)
    await auth_service.change_password(
        user_id,
        data.current_password,
        data.new_password
    )
    
    return MessageResponse(
        message="Password changed successfully.",
        success=True
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using refresh token.
    """
    auth_service = AuthService(db)
    return await auth_service.refresh_tokens(data.refresh_token)


@router.post("/logout", response_model=MessageResponse)
async def logout(
    user_id: str = Depends(get_current_user_id)
):
    """
    Logout user.
    
    Note: With JWT, logout is handled client-side by removing tokens.
    This endpoint is for any server-side cleanup if needed.
    """
    # TODO: Add token to blacklist if implementing token revocation
    
    return MessageResponse(
        message="Logged out successfully.",
        success=True
    )
