import axios from 'axios';
import {OpenWeatherMapResponse, WeatherResponse} from "../../../types/weather";

const OPENWEATHERMAP_BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
const ICON_BASE_URL = 'https://openweathermap.org/img/wn';

export default class WeatherService {
    private apiKey: string;

    constructor() {
        this.apiKey = process.env.OPEN_WEATHER_API_KEY || '';

        if (!this.apiKey) {
            throw new Error('OPEN_WEATHER_API_KEY is not configured');
        }
    }

    public async getWeather(lat: number, lon: number): Promise<WeatherResponse> {
        const url = `${OPENWEATHERMAP_BASE_URL}?lat=${lat}&lon=${lon}&appid=${this.apiKey}&units=metric`;

        const response = await axios.get<OpenWeatherMapResponse>(url);
        const data = response.data;

        // Combine all weather descriptions
        const weatherDescriptions = data.weather
            .map(w => this.capitalizeFirst(w.description))
            .join(', ');

        // Use first weather item's icon
        const iconCode = data.weather[0]?.icon || '01d';
        const iconUrl = `${ICON_BASE_URL}/${iconCode}.png`;

        return {
            city: data.name,
            weather: weatherDescriptions,
            temperature: `${Math.floor(data.main.temp)}°`,
            icon: iconUrl
        };
    }

    private capitalizeFirst(str: string): string {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
}
