import {Request, Response} from "express";
import path from "path";
import {readFileSync} from "fs";

const packageJsonPath = path.resolve(process.cwd(), "package.json");
const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));

export default class StatusController {
    public getStatus = async (request: Request, response: Response) => {
        return response.status(200).json({
            engine: "running",
            version: packageJson.version,
            app: packageJson.name
        });
    }
}
