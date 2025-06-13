import express, {Application, Request, Response} from "express";
import cors from "cors";
import bodyParser from "body-parser";
import {useRoutes} from './init.routes.impl';
import errorHandler from "./error.handler.impl";
import controlHeaders from "./control.headers.impl";
import {contextMiddleware} from "./context.request.impl";

const server: Application = express();

server.use((req, res, next) => {
    const startTime: number = Date.now();
    const originalJson = res.json;
    res.json = function (data) {
        data.time = Date.now() - startTime;
        data.entity = `android.health-connect.api`;
        return originalJson.call(this, data);
    };
    next();
});

// cors handler
server.use(cors({
    origin: '*',
    methods: "*",
    allowedHeaders: '*',
    exposedHeaders: '*',
}));

// body parser
server.use(express.json());
server.use(bodyParser.json({limit: '15mb'}));
server.use(bodyParser.urlencoded({extended: true, limit: '15mb'}));

// context middleware
server.use(contextMiddleware)

// control headers
server.use(controlHeaders);

// Load routes
useRoutes(server);

// Handle errors
server.use(errorHandler);

// Load Default Route
server.use("*", (req: Request, res: Response) => {
    res.status(404).json({
        status: false,
        error: "Route not found"
    });
});

export default server;