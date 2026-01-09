export default class HealthService {
    public async logPermission(permissionName: string, data: any = null): Promise<void> {
        console.log(`Permission: ${permissionName}`, data);
    }
}
