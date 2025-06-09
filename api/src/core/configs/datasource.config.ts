/**
 * Data Source
 * @description: This file is responsible for creating a new DataSource instance
 * @requires: typeorm, dotenv
 * @exports: AppDataSource
 * @type: DataSource
 */
import {DataSource} from "typeorm"
import {DataSourceOptions} from "typeorm/data-source/DataSourceOptions";

/**
 * Load environment variables
 */
import {config} from "dotenv";

config();

/**
 * Data Source Configurations
 * @type {DataSourceOptions}
 * @constructor
 * @param {string} type
 * @param {string} host
 * @param {number} port
 * @param {string} database
 * @param {string} username
 * @param {string} password
 * @param {boolean} synchronize
 * @param {boolean} logging
 * @param {string[]} entities
 * @param {string[]} migrations
 */
const AppDataSourceConfigs: DataSourceOptions = {
    type: "mongodb",
    host: process.env.DB_HOST || "localhost",
    port: Number(process.env.DB_PORT) || 27017,
    database: process.env.DB_NAME,
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    synchronize: false,
    logging: false,
    ssl: false,
    entities: [`${__dirname}/../../database/entities/**/*`],
};

/**
 * Data Source Instance
 * @type {DataSource}
 * @constructor
 * @param {DataSourceOptions} AppDataSourceConfigs
 */
const AppDataSource: DataSource = new DataSource(AppDataSourceConfigs);

export default AppDataSource;