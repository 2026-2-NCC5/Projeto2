from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdateRequest

router = APIRouter(prefix="/profile", tags=["Perfil e Preferências"])


@router.get("", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    """
    Retorna os dados consolidados do perfil do usuário autenticado (RF02).
    Acesso restrito exclusivamente aos dados autorizados do próprio estudante.
    """
    return current_user


@router.patch("", response_model=UserResponse)
def update_profile_preferences(
    update_data: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Atualiza as preferências do usuário, incluindo acessibilidade (escala de texto/contraste).
    """
    if update_data.font_size_factor is not None:
        if update_data.font_size_factor not in ["small", "normal", "medium", "large"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tamanho de fonte inválido. Opções válidas: small, normal, medium, large.",
            )
        current_user.font_size_factor = update_data.font_size_factor

    if update_data.high_contrast is not None:
        current_user.high_contrast = update_data.high_contrast

    if update_data.notifications_enabled is not None:
        current_user.notifications_enabled = update_data.notifications_enabled

    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user
