/// <reference path="../types/app.d.ts" />
import * as dotenv from "dotenv";

dotenv.config();

import "reflect-metadata";


import process from "process";

import server from "./core/infrastructure/create.server.impl";
import initDatasource from "./core/infrastructure/init.datasource.impl";

const APP_PORT: string = process.env.APPLICATION_PORT;

console.log("Starting server... \nPORT: " + APP_PORT);
// Load server
server.listen(APP_PORT, async () => {
    // Initialize DataSource
    await initDatasource();
    console.log(`server running: http://localhost:${APP_PORT}`)
}).on("error", (err) => {
    console.error("Server error: \n" + err);
});
