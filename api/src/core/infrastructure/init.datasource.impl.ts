import AppDataSource from "../configs/datasource.config";

export default async function initDatasource(): Promise<void> {
    if (!AppDataSource.isInitialized) {
        await AppDataSource.initialize()
            .then(() => {
                console.log("Data Source has been initialized!")
            })
            .catch(async (err) => {
                console.error("Error during Data Source initialization", err)
                throw err;
            }).finally(() => {
                console.log(`Data Source: ${AppDataSource.driver.options.type}`)
            });
    } else {
        console.log("Data Source already initialized!");
    }
}