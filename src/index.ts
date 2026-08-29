import "reflect-metadata";
import {createConnection} from "typeorm";
import {Request, Response} from "express";
import * as express from "express";
import * as bodyParser from "body-parser";
import {AppRoutes} from "./routes";

/**
 * Connects to the database with retry/backoff instead of giving up on the
 * first failure. On startup in Kubernetes there is no ordering guarantee
 * between this app's pod and the database becoming reachable (DNS
 * propagation, the DB still initializing, a rolling restart, ...), so a
 * transient failure here should not be fatal.
 */
async function connectWithRetry(retries = 10, delayMs = 3000) {
    for (let attempt = 1; ; attempt++) {
        try {
            return await createConnection();
        } catch (error) {
            if (attempt >= retries) {
                throw error;
            }
            console.log(`TypeORM connection attempt ${attempt}/${retries} failed, retrying in ${delayMs}ms: `, error.message || error);
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }
    }
}

// create connection with database
// note that it's not active database connection
// TypeORM creates connection pools and uses them for your requests
connectWithRetry().then(async connection => {

    // create express app
    const app = express();
    app.use(bodyParser.json());

    // register all application routes
    AppRoutes.forEach(route => {
        app[route.method](route.path, (request: Request, response: Response, next: Function) => {
            route.action(request, response)
                .then(() => next)
                .catch(err => next(err));
        });
    });

    // run app
    const port = Number(process.env.PORT) || 3000;
    app.listen(port);

    console.log(`Express application is up and running on port ${port}`);

}).catch(error => {
    // Retries were exhausted: surface a fatal error and exit non-zero so the
    // orchestrator restarts the container, instead of leaving a process
    // alive that never opened its HTTP port.
    console.log("TypeORM connection error: ", error);
    process.exit(1);
});
