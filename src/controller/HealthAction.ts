import {Request, Response} from "express";

/**
 * Lightweight liveness check: confirms the process is up and responsive,
 * without touching the database. Kept separate from a readiness/DB check so
 * a slow or unavailable database does not cause the process itself to be
 * killed and restarted by the orchestrator.
 */
export async function healthAction(request: Request, response: Response) {
    response.send({status: "ok"});
}
