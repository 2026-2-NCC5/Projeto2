from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.database import get_db
from app.core.security import verify_password, create_access_token, get_current_user
from app.core.config import settings
from app.models.user import User
from app.models.audit import AuditLog
from app.schemas.user import LoginRequest, TokenResponse, UserResponse

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/login", response_model=TokenResponse)
def login(login_data: LoginRequest, request: Request, db: Session = Depends(get_db)):
    """
    Realiza login com RA ou E-mail institucional e senha (RF01).
    Gera token JWT contendo perfil e permissões do usuário.
    """
    identifier = login_data.ra_or_email.strip()
    user = db.query(User).filter(
        or_(
            User.ra_or_email == identifier,
            User.email == identifier,
            User.ra == identifier,
        )
    ).first()

    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="RA/E-mail ou senha incorretos. Verifique suas credenciais.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Conta desativada. Entre em contato com a Secretaria Geral.",
        )

    # Registro de auditoria (RF10)
    audit_entry = AuditLog(
        user_id=user.id,
        action="LOGIN_SUCCESS",
        details={
            "identifier": identifier,
            "profile_type": user.profile_type.value,
        },
        ip_address=request.client.host if request.client else None,
    )
    db.add(audit_entry)
    db.commit()

    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "ra_or_email": user.ra_or_email,
            "profile_type": user.profile_type.value,
            "full_name": user.full_name,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user,
    }


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Retorna os dados do usuário autenticado a partir do token JWT."""
    return current_user


@router.post("/recover-password")
def recover_password(identifier_data: dict, db: Session = Depends(get_db)):
    """
    Fluxo de recuperação de senha por link institucional (Tela 4 do Figma).
    """
    identifier = identifier_data.get("ra_or_email", "").strip()
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Informe seu RA ou e-mail institucional.",
        )

    user = db.query(User).filter(
        or_(
            User.ra_or_email == identifier,
            User.email == identifier,
            User.ra == identifier,
        )
    ).first()

    # Mesmo se não encontrar, retornamos mensagem padrão por segurança
    return {
        "message": f"Se o RA/E-mail '{identifier}' estiver cadastrado, as instruções de recuperação foram enviadas ao e-mail institucional.",
        "success": True,
    }
