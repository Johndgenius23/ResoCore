# ResoCore Smart Contract  

**ResoCore** is a Clarity-based smart contract designed to streamline and automate the management of urban resources in smart cities. By leveraging blockchain technology, ResoCore ensures transparency, accountability, and efficiency in handling parking, waste management, and energy distribution.

---

## Features  

### 1. **Resource Management**  
- **Register Resources**: Administrators can register new resources, specifying their type, location, capacity, and pricing.  
- **Retrieve Resource Details**: View detailed information about any resource by ID.  

### 2. **Parking Management**  
- **Reserve Parking**: Citizens can reserve parking spots by paying a fee proportional to the duration.  
- **Monitor Parking Status**: Retrieve real-time information about parking availability and occupancy.  

### 3. **Waste Management**  
- **Update Waste Levels**: IoT devices or authorized entities can update the fill level of waste bins.  
- **Service Notifications**: Automatically flags waste bins that require servicing based on their fill levels.  

### 4. **Energy Management**  
- **Allocate Energy**: Users can purchase and allocate energy for consumption.  
- **Track Energy Usage**: Monitor energy allocations and consumption history.  

### 5. **IoT Device Integration**  
- **Register IoT Devices**: Administrators can register IoT devices linked to resources for real-time updates and monitoring.  
- **Device Status Check**: Verify the status and activity of IoT devices.  

---

## Data Structures  

### **Resource Types**  
- Parking: `RESOURCE-TYPE-PARKING`  
- Waste: `RESOURCE-TYPE-WASTE`  
- Energy: `RESOURCE-TYPE-ENERGY`  

### **Maps**  
- `resources`: Stores details of registered resources.  
- `parking-spots`: Tracks parking spot occupancy and reservations.  
- `waste-bins`: Maintains data on waste bin levels and service needs.  
- `energy-consumption`: Manages user energy allocation and usage.  
- `iot-devices`: Stores details of IoT devices linked to resources.  

---

## Error Codes  

- `ERR-NOT-AUTHORIZED` (`u1`): Action requires admin privileges or valid authorization.  
- `ERR-INVALID-RESOURCE` (`u2`): Resource not found or invalid.  
- `ERR-RESOURCE-UNAVAILABLE` (`u3`): Resource is unavailable for the requested action.  
- `ERR-INVALID-PARAMS` (`u4`): Provided parameters are invalid.  
- `ERR-INSUFFICIENT-PAYMENT` (`u5`): Payment amount is insufficient for the requested action.  

---

## Functions  

### Public Functions  
- `register-resource`: Registers a new resource.  
- `reserve-parking`: Reserves a parking spot.  
- `update-waste-level`: Updates the fill level of a waste bin.  
- `allocate-energy`: Allocates energy to a user.  
- `register-iot-device`: Registers an IoT device for a resource.  

### Read-Only Functions  
- `get-resource-details`: Retrieves details of a specific resource.  
- `get-parking-status`: Retrieves parking spot status by resource ID.  
- `get-waste-bin-status`: Retrieves the status of a specific waste bin.  
- `get-energy-usage`: Retrieves energy usage details for a user.  
- `get-device-status`: Retrieves the status of a specific IoT device.  

---

## Installation  

1. Clone the repository containing ResoCore.  
2. Deploy the contract on a Stacks-compatible blockchain network using the Clarity development tools.  
3. Configure the `admin` account by setting the principal of the contract owner.  

---

## Usage  

### Admin Actions  
- Use `register-resource` to add resources like parking lots, waste bins, or energy grids.  
- Register IoT devices with `register-iot-device` for enhanced monitoring and automation.  

### Citizen Actions  
- Reserve parking spots using `reserve-parking`.  
- Allocate energy for consumption via `allocate-energy`.  

### IoT Device Integration  
- Send updates about resource usage or availability using functions like `update-waste-level`.  

---

## Security  

- Only authorized administrators can register resources and IoT devices.  
- Payments are processed securely using the `stx-transfer?` function.  
- Resource availability is strictly validated to prevent over-allocation.  

---

## Future Improvements  

1. **Dynamic Pricing**: Implement variable pricing for resources based on demand.  
2. **Enhanced IoT Integration**: Add more IoT device types and advanced monitoring capabilities.  
3. **Cross-City Data Sharing**: Enable integration with other city systems for resource optimization.  

---

**ResoCore** is the foundation of a smarter, more sustainable urban future. Deploy it today and take a step toward a truly smart city.