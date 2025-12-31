export default class HealthService {
    public async logPermission(permissionName: string): Promise<void> {
        console.log(`Permission: ${permissionName}`);
    }
}
