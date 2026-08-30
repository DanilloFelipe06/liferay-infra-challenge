import {Connection} from "typeorm";
import {connectWithRetry} from "../src/connectWithRetry";

/**
 * Unit tests for the startup retry/backoff logic (src/connectWithRetry.ts)
 * — the piece that makes the app tolerant of the database not being
 * reachable yet at pod startup (see the comment on it, and
 * charts/posts-api's rollout ordering). `connect` is mocked so these run
 * instantly under fake timers instead of waiting out real delays.
 */
describe("connectWithRetry", () => {
    beforeEach(() => {
        jest.useFakeTimers();
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("returns the connection immediately on the first successful attempt", async () => {
        const fakeConnection = {} as Connection;
        const connect = jest.fn().mockResolvedValue(fakeConnection);

        const result = await connectWithRetry(5, 10, connect);

        expect(result).toBe(fakeConnection);
        expect(connect).toHaveBeenCalledTimes(1);
    });

    it("retries with a delay between attempts and succeeds once the database comes up", async () => {
        const fakeConnection = {} as Connection;
        const connect = jest.fn()
            .mockRejectedValueOnce(new Error("connection refused"))
            .mockRejectedValueOnce(new Error("connection refused"))
            .mockResolvedValueOnce(fakeConnection);

        const promise = connectWithRetry(5, 10, connect);
        await jest.runAllTimersAsync();

        await expect(promise).resolves.toBe(fakeConnection);
        expect(connect).toHaveBeenCalledTimes(3);
    });

    it("gives up and rejects once retries are exhausted", async () => {
        const error = new Error("still down");
        const connect = jest.fn().mockRejectedValue(error);

        const promise = connectWithRetry(3, 10, connect);
        // Attach the rejection assertion before advancing timers: once
        // runAllTimersAsync lets the final attempt's rejection through,
        // an unattached rejection would otherwise be flagged by Jest as
        // an unhandled promise rejection before this line ever runs.
        const assertion = expect(promise).rejects.toThrow("still down");
        await jest.runAllTimersAsync();
        await assertion;

        expect(connect).toHaveBeenCalledTimes(3);
    });
});
