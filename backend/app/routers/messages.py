import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.auth import get_current_patient
from app.database import get_db
from app.models import Group, Message, Patient
from app.schemas import GroupListOut, GroupOut, MessageCreate, MessageListOut, MessageOut

router = APIRouter(tags=["messages"])


# ── Messages ───────────────────────────────────────────────────────────────────
@router.get("/patients/me/messages", response_model=MessageListOut)
def list_messages(
    category: str | None = Query(None),
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
    is_read: bool | None = None,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> MessageListOut:
    q = select(Message).where(Message.recipient_id == current.patient_id)
    if category and category != "all":
        q = q.where(Message.category == category)
    if is_read is not None:
        q = q.where(Message.is_read.is_(is_read))

    total = db.execute(select(func.count()).select_from(q.subquery())).scalar_one()
    rows = db.execute(q.order_by(Message.sent_at.desc()).limit(limit).offset(offset)).scalars().all()

    return MessageListOut(
        total=total,
        messages=[MessageOut.model_validate(m) for m in rows],
    )


@router.post("/patients/me/messages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def send_message(
    body: MessageCreate,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> MessageOut:
    msg = Message(
        thread_id=str(uuid.uuid4()),
        sender_id=current.patient_id,
        recipient_id=body.recipient_id,
        category=body.category,
        subject=body.subject,
        body=body.body,
        sender_name=current.full_name,
        sender_avatar_url=current.avatar_url,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return MessageOut.model_validate(msg)


@router.patch("/patients/me/messages/{message_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_read(
    message_id: str,
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> None:
    msg = db.execute(
        select(Message).where(Message.message_id == message_id, Message.recipient_id == current.patient_id)
    ).scalar_one_or_none()
    if not msg:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Message not found")
    msg.is_read = True
    db.commit()


# ── Groups ─────────────────────────────────────────────────────────────────────
@router.get("/groups", response_model=GroupListOut)
def list_groups(
    current: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> GroupListOut:
    rows = db.execute(select(Group).order_by(Group.is_featured.desc())).scalars().all()
    return GroupListOut(groups=[GroupOut.model_validate(g) for g in rows])
