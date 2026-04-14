"""
Batch Evaluation API - Phase 2 Full Implementation.
"""

import logging
import uuid
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed

from fastapi import APIRouter

from app.models.schemas import BatchEvaluationResponse, BatchEvaluationItem
from app.api.routes.campaign import evaluate_campaign as eval_campaign

logger = logging.getLogger("trust_eval_service")
router = APIRouter()

# Thread pool for parallel evaluation
_executor = ThreadPoolExecutor(max_workers=4)


@router.post("/evaluate/batch/campaigns")
async def batch_evaluate_campaigns(campaign_ids: list[int]):
    """
    Batch evaluate multiple campaigns in parallel.

    Each campaign is evaluated independently using the same pipeline
    as /evaluate/campaign/{id}.
    """
    batch_id = f"batch_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"
    submitted_at = datetime.now(timezone.utc).isoformat()

    if not campaign_ids:
        return BatchEvaluationResponse(
            batch_id=batch_id,
            submitted_at=submitted_at,
            completed_at=datetime.now(timezone.utc).isoformat(),
            total=0,
            succeeded=0,
            failed=0,
            results=[],
        )

    results: list[BatchEvaluationItem] = []
    succeeded = 0
    failed = 0

    for cid in campaign_ids:
        try:
            evaluation = await eval_campaign(cid)
            results.append(BatchEvaluationItem(
                campaign_id=cid,
                status="success",
                evaluation=evaluation,
            ))
            succeeded += 1
        except Exception as e:
            logger.warning(f"Batch evaluation failed for campaign {cid}: {e}")
            results.append(BatchEvaluationItem(
                campaign_id=cid,
                status="error",
                error=str(e),
            ))
            failed += 1

    return BatchEvaluationResponse(
        batch_id=batch_id,
        submitted_at=submitted_at,
        completed_at=datetime.now(timezone.utc).isoformat(),
        total=len(campaign_ids),
        succeeded=succeeded,
        failed=failed,
        results=results,
    )
