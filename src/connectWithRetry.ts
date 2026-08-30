import {Connection, ConnectionOptions, createConnection} from "typeorm";

/**
 * Connects to the database with retry/backoff instead of giving up on the
 * first failure. On startup in Kubernetes there is no ordering guarantee
 * between this app's pod and the database becoming reachable (DNS
 * propagation, the DB still initializing, a rolling restart, ...), so a
 * transient failure here should not be fatal.
 *
 * `connect` is injectable (defaults to TypeORM's own createConnection) so
 * tests can exercise the retry/backoff behavior without a real database.
 */
export async function connectWithRetry(
    retries = 10,
    delayMs = 3000,
    connect: (options?: ConnectionOptions) => Promise<Connection> = createConnection
): Promise<Connection> {
    for (let attempt = 1; ; attempt++) {
        try {
            return await connect();
        } catch (error) {
            if (attempt >= retries) {
                throw error;
            }
            console.log(`TypeORM connection attempt ${attempt}/${retries} failed, retrying in ${delayMs}ms: `, error.message || error);
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }
    }
}
