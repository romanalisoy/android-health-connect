import {Routing} from "../../core/infrastructure/init.routes.impl";
import {authMiddleware} from "../middlewares/auth.middleware";
import {getWeatherValidation} from "../validations/weather.validation";
import WeatherController from "../controllers/weather.controller";

const router: Routing = new Routing();

// Get weather by coordinates
router
    .middleware(authMiddleware)
    .validation(getWeatherValidation)
    .post('/', [WeatherController, 'getWeather']);

export default {
    router: router.getRouter(),
    prefix: 'weather',
    apiVersion: 1
};
