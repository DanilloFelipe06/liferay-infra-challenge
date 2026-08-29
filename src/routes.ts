import {postGetAllAction} from "./controller/PostGetAllAction";
import {postGetByIdAction} from "./controller/PostGetByIdAction";
import {postSaveAction} from "./controller/PostSaveAction";
import {healthAction} from "./controller/HealthAction";

/**
 * All application routes.
 */
export const AppRoutes = [
    {
        path: "/health",
        method: "get",
        action: healthAction
    },
    {
        path: "/posts",
        method: "get",
        action: postGetAllAction
    },
    {
        path: "/posts/:id",
        method: "get",
        action: postGetByIdAction
    },
    {
        path: "/posts",
        method: "post",
        action: postSaveAction
    }
];