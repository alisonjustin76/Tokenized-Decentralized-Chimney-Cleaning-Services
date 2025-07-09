# Tokenized Decentralized Chimney Cleaning Services

A blockchain-based platform for managing chimney cleaning services, safety inspections, and maintenance coordination using Stacks blockchain and Clarity smart contracts.

## Overview

This system provides a decentralized solution for chimney cleaning services with the following key features:

- **Inspection Scheduling**: Coordinates annual safety and maintenance checks
- **Creosote Monitoring**: Tracks dangerous buildup levels requiring cleaning
- **Fire Prevention**: Ensures proper ventilation and safety compliance
- **Equipment Certification**: Verifies cleaning tool quality and effectiveness
- **Insurance Coordination**: Manages liability coverage for service providers

## Smart Contracts

### 1. Inspection Scheduling Contract (\`inspection-scheduling.clar\`)
- Schedule annual safety inspections
- Track inspection status and results
- Manage inspector assignments
- Handle inspection payments

### 2. Creosote Monitoring Contract (\`creosote-monitoring.clar\`)
- Monitor creosote buildup levels
- Set danger thresholds
- Alert system for required cleaning
- Track measurement history

### 3. Fire Prevention Contract (\`fire-prevention.clar\`)
- Ensure ventilation compliance
- Safety standard verification
- Risk assessment tracking
- Emergency protocol management

### 4. Equipment Certification Contract (\`equipment-certification.clar\`)
- Certify cleaning tools and equipment
- Track equipment quality ratings
- Manage certification expiry
- Verify tool effectiveness

### 5. Insurance Coordination Contract (\`insurance-coordination.clar\`)
- Manage liability coverage
- Track insurance policies
- Handle claims processing
- Coordinate provider coverage

## Token Economics

The platform uses a native token system for:
- Service payments
- Staking for service providers
- Governance participation
- Reward distribution

## Getting Started

### Prerequisites
- Stacks blockchain node
- Clarity development environment
- Node.js for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet

### Testing

Tests are written using Vitest and cover:
- Contract deployment
- Function execution
- Error handling
- Edge cases
- Integration scenarios

## Contract Architecture

Each contract is designed to be independent with no cross-contract calls, following best practices for security and maintainability.

## Security Features

- Multi-signature requirements for critical operations
- Time-locked functions for safety
- Role-based access control
- Emergency pause functionality

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

MIT License - see LICENSE file for details.
