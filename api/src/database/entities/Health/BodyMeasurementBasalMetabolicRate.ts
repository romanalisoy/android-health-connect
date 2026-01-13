import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_basal_metabolic_rate',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementBasalMetabolicRate extends BodyMeasurementBase implements IModel {
    @Column()
    basalMetabolicRate!: number;
}
