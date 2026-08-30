import * as request from "supertest";
import * as express from "express";
import {createConnection, getConnection} from "typeorm";
import {createApp} from "../src/app";
import {Post} from "../src/entity/Post";
import {Category} from "../src/entity/Category";

/**
 * Functional tests for the HTTP layer, exercised through the real Express
 * app + a real (SQLite, in-memory) TypeORM connection — no mocking of the
 * ORM itself, since the entity/repository behavior is exactly what's
 * worth catching regressions in.
 */
describe("posts API", () => {
    let app: express.Express;

    beforeAll(async () => {
        await createConnection({
            type: "sqlite",
            database: ":memory:",
            dropSchema: true,
            entities: [Post, Category],
            synchronize: true,
            logging: false
        });
        app = createApp();
    });

    afterAll(async () => {
        await getConnection().close();
    });

    it("GET /health returns ok", async () => {
        const res = await request(app).get("/health");

        expect(res.status).toBe(200);
        expect(res.body).toEqual({status: "ok"});
    });

    it("GET /posts returns an empty list before anything is created", async () => {
        const res = await request(app).get("/posts");

        expect(res.status).toBe(200);
        expect(res.body).toEqual([]);
    });

    it("POST /posts creates a post, and GET /posts/:id retrieves it back", async () => {
        const created = await request(app)
            .post("/posts")
            .send({title: "Hello", text: "World"});

        expect(created.status).toBe(200);
        expect(created.body.id).toBeDefined();
        expect(created.body).toMatchObject({title: "Hello", text: "World"});

        const fetched = await request(app).get(`/posts/${created.body.id}`);

        expect(fetched.status).toBe(200);
        expect(fetched.body).toMatchObject({title: "Hello", text: "World"});
    });

    it("GET /posts/:id returns 404 for a post that doesn't exist", async () => {
        const res = await request(app).get("/posts/999999");

        expect(res.status).toBe(404);
    });

    it("GET /posts includes posts created earlier", async () => {
        await request(app).post("/posts").send({title: "Second", text: "Post"});

        const res = await request(app).get("/posts");

        expect(res.status).toBe(200);
        expect(res.body.length).toBeGreaterThanOrEqual(2);
        expect(res.body.map((p: Post) => p.title)).toEqual(
            expect.arrayContaining(["Hello", "Second"])
        );
    });
});
