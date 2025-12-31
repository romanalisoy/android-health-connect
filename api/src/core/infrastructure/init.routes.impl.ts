import {readdirSync} from "fs";
import path from "path";
import {Router, RequestHandler, Request, Response, NextFunction, Application} from 'express';


function controllerHandler(ControllerClass: new () => any, methodName: string): RequestHandler {
    return async (req: Request, res: Response, next: NextFunction) => {
        const controllerInstance = new ControllerClass();
        if (typeof controllerInstance[methodName] === 'function') {
            try {
                await controllerInstance[methodName](req, res, next);
            } catch (error) {
                next(error);
            }
        } else {
            next(new Error(`Method ${methodName} is not a function on ${ControllerClass.name}`));
        }
    };
}


export function useRoutes(app: Application) {
    const routesPath: string = path.join(__dirname, '../../http/routes');

    const files: string[] = readdirSync(routesPath).filter(file => {
        return file.endsWith('.route.ts') || file.endsWith('.route.js');
    });

    files.forEach(file => {
        const routeModule = require(path.join(routesPath, file)).default;
        const basePath = `/api/v${routeModule.apiVersion}/${routeModule.prefix}`;
        app.use(basePath, routeModule.router);
        console.log(`Loaded routes: /api/v${routeModule.apiVersion}/${routeModule.prefix}`);
    });
}


type RouteHandler = RequestHandler | [new () => any, string];
type Middleware = RequestHandler | RequestHandler[];

export class Routing {
    private readonly router: Router;
    private middlewares: RequestHandler[] = [];

    public get!: (path: string, handler: RouteHandler) => this;
    public post!: (path: string, handler: RouteHandler) => this;
    public put!: (path: string, handler: RouteHandler) => this;
    public patch!: (path: string, handler: RouteHandler) => this;
    public delete!: (path: string, handler: RouteHandler) => this;

    constructor() {
        this.router = Router({ mergeParams: true });

        ['get', 'post', 'put', 'patch', 'delete'].forEach(method => {
            (this as any)[method] = (path: string, handler: RouteHandler) => {
                const fullHandler = [...this.middlewares, this.wrapHandler(handler)];
                this.router[method](path, fullHandler);

                this.middlewares = [];
                return this;
            };
        });
    }

    public middleware(middleware: Middleware): this {
        if (Array.isArray(middleware)) {
            this.middlewares.push(...middleware);
        } else {
            this.middlewares.push(middleware);
        }
        return this;
    }

    public validation(validation: Middleware): this {
        if (Array.isArray(validation)) {
            this.middlewares.push(...validation);
        } else {
            this.middlewares.push(validation);
        }
        return this;
    }

    private wrapHandler(handler: RouteHandler): RequestHandler {
        return controllerHandler(handler[0], handler[1]);
    }

    public getRouter(): Router {
        return this.router;
    }
}
