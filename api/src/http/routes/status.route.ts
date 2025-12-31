import {Routing} from "../../core/infrastructure/init.routes.impl";
import StatusController from "../controllers/status.controller";

const router: Routing = new Routing();

router.get('/', [StatusController, 'getStatus']);

export default {
    router: router.getRouter(),
    prefix: 'status',
    apiVersion: 1,
};
