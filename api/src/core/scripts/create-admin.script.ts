import "reflect-metadata";
import {config} from "dotenv";
import {randomUUID} from "crypto";
import bcrypt from "bcrypt";
import AppDataSource from "../configs/datasource.config";
import User from "../../database/entities/User";

config();

type CliArgs = {
    id?: string;
    email?: string;
    password?: string;
    fcmToken?: string;
    full_name?: string;
};

const args = process.argv.slice(2);

function readArg(name: keyof CliArgs): string | undefined {
    const flag = `--${name}`;
    const eq = args.find(arg => arg.startsWith(`${flag}=`));
    if (eq) return eq.slice(flag.length + 1);
    const idx = args.findIndex(arg => arg === flag);
    if (idx !== -1 && args[idx + 1]) return args[idx + 1];
    return undefined;
}

function printUsage(): void {
    console.log("Usage:");
    console.log("node dist/core/scripts/create-admin.script.js --email <email> --password <password> --full_name <name> [--fcmToken <token>] [--id <id>]");
}

async function run(): Promise<void> {
    if (args.includes("--help") || args.includes("-h")) {
        printUsage();
        return;
    }

    const input: CliArgs = {
        id: readArg("id"),
        email: readArg("email"),
        password: readArg("password"),
        fcmToken: readArg("fcmToken"),
        full_name: readArg("full_name")
    };

    if (!input.email || !input.password || !input.full_name) {
        console.error("Missing required arguments.");
        printUsage();
        process.exit(1);
    }

    try {
        await AppDataSource.initialize();
        const userRepo = AppDataSource.getMongoRepository(User);

        const existing = await userRepo.findOne({where: {email: input.email}});
        if (existing) {
            console.log(`User already exists: ${input.email}`);
            return;
        }

        const hashedPassword = await bcrypt.hash(input.password, 10);

        const user = userRepo.create({
            id: input.id || randomUUID(),
            email: input.email,
            password: hashedPassword,
            fcmToken: input.fcmToken || "",
            full_name: input.full_name
        });

        await userRepo.save(user);
        console.log(`Admin user created: ${input.email}`);
    } catch (error) {
        console.error("Failed to create admin user:", error);
        process.exit(1);
    } finally {
        if (AppDataSource.isInitialized) {
            await AppDataSource.destroy();
        }
    }
}

run();
