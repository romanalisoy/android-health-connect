export interface WeatherRequest {
    lat: number;
    lon: number;
}

export interface WeatherResponse {
    city: string;
    weather: string;
    temperature: string;
    icon: string;
}

// OpenWeatherMap API Response types
export interface OpenWeatherMapResponse {
    coord: {
        lon: number;
        lat: number;
    };
    weather: OpenWeatherMapWeather[];
    base: string;
    main: {
        temp: number;
        feels_like: number;
        temp_min: number;
        temp_max: number;
        pressure: number;
        humidity: number;
        sea_level?: number;
        grnd_level?: number;
    };
    visibility: number;
    wind: {
        speed: number;
        deg: number;
    };
    clouds: {
        all: number;
    };
    dt: number;
    sys: {
        type?: number;
        id?: number;
        country: string;
        sunrise: number;
        sunset: number;
    };
    timezone: number;
    id: number;
    name: string;
    cod: number;
}

export interface OpenWeatherMapWeather {
    id: number;
    main: string;
    description: string;
    icon: string;
}
