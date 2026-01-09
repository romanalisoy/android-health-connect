import {Request, Response} from 'express';
import {HttpStatusCode} from "axios";
import WeatherService from "../../core/services/weather.service";

export default class WeatherController {
    private service: WeatherService;

    constructor() {
        this.service = new WeatherService();
    }

    public getWeather = async (request: Request, response: Response) => {
        try {
            const {lat, lon} = request.body;

            const weather = await this.service.getWeather(lat, lon);

            return response.status(HttpStatusCode.Ok).json({
                success: true,
                data: weather
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : 'An error occurred';

            return response.status(HttpStatusCode.BadRequest).json({
                success: false,
                message
            });
        }
    }
}
