import {Routing} from "../src/core/infrastructure/init.routes.impl";
import {User} from "./user";

declare global {
    type DateString = Date | string;

    interface app {
        router: Routing;
        apiVersion: number;
        prefix: string;
    }

    interface IModel {
    }

    namespace Express {
        export interface Request {
            user?: User;
            input(key: string, defaultValue: any): any;
            getHeader(key: string, defaultValue: any): any;
            queryParams(key: string, defaultValue: any): any;
            filters(): any;
            page(): number;
            limit(): number;
        }
    }

    interface TimeZoneOffset {
        id: string;
        totalSeconds: number;
    }
}

export {};