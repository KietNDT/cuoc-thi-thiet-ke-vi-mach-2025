# cuoc-thi-thiet-ke-vi-mach-2025
Cuộc thi thiết kế vi mạch cho đô thị xanh 2025.

# FPGA-Based Environmental Sensor Noise Filtering

## Overview

This project implements digital signal filtering algorithms for environmental sensors on FPGA using Verilog HDL.

The objective is to improve sensor data reliability by reducing measurement noise while maintaining low hardware complexity and real-time performance.

The project is being developed using Quartus Prime and targets Intel FPGA platforms such as the DE1-SoC.

---

## Sensors

The system processes three digital environmental sensors:

- PM2.5 Sensor
- Temperature Sensor
- Humidity Sensor

---

## Filtering Algorithms

Different sensors exhibit different noise characteristics, therefore different filtering methods are applied.

| Sensor | Main Noise | Filter |
|---------|------------|--------|
| PM2.5 | Spike, rapid fluctuation | Median(3) + Moving Average(8) |
| Temperature | Small random noise | Moving Average(8) |
| Humidity | Step changes, outliers | Moving Average(8) + Outlier Detection |

---

## Development Flow

1. Generate simulated sensor data
2. Implement filtering algorithms in Verilog
3. Verify functionality using ModelSim
4. Compare FPGA output with software reference
5. Synthesize design using Quartus Prime
6. Deploy to FPGA hardware

---

## Development Tools

- Verilog HDL
- Quartus II 13.01sp1 (64-bit)
- ModelSim Intel FPGA Edition
- Python (NumPy, SciPy)
- Git & GitHub

---

## Project Status

Current progress:

- Algorithm selection completed
- RTL architecture designed
- Verilog implementation in progress
- Simulation and verification ongoing

---

## Future Work

- FPGA implementation on DE1-SoC
- UART communication with sensors
- Performance evaluation (MAE/RMSE)
- Hardware optimization
- Real sensor integration

---

## Authors
Triệu Quốc Huy (Leader)
[@Trieu-Huy](https://github.com/Trieu-Huy)


Nguyễn Đức Tấn Kiệt
[@KietNDT](https://github.com/KietNDT)


Phan Khánh Tâm
[@Tam-sketch](https://github.com/Tam-sketch)

Nguyễn Đức Trọng

UIT - University of Information Technology

2025
