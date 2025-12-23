import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '${{ values.port }}', 10),
  environment: process.env.NODE_ENV || '${{ values.environment }}',
  name: '${{ values.name }}',
};
