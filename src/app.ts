import {Request, Response} from "express";
import * as express from "express";
import * as bodyParser from "body-parser";
import {AppRoutes} from "./routes";

/**
 * Builds the Express app (routes wired up, JSON body parsing enabled) but
 * does not open a port and does not touch the database connection. Split
 * out from index.ts so tests can exercise the HTTP layer directly (e.g.
 * with supertest) against whatever TypeORM connection they set up,
 * without needing index.ts's retry/listen/process.exit concerns.
 */
export function createApp(): express.Express {
    const app = express();
    app.use(bodyParser.json());

    AppRoutes.forEach(route => {
        app[route.method](route.path, (request: Request, response: Response, next: Function) => {
            route.action(request, response)
                .then(() => next)
                .catch(err => next(err));
        });
    });

    return app;
}
