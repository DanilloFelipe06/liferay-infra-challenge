import "reflect-metadata";
import {createApp} from "./app";
import {connectWithRetry} from "./connectWithRetry";

// create connection with database
// note that it's not active database connection
// TypeORM creates connection pools and uses them for your requests
connectWithRetry().then(async () => {

    const app = createApp();

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
