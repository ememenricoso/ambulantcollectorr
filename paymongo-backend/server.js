const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config(); // Use dotenv for environment variables

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// Endpoint to create payment intent
app.post('/create-payment-intent', async (req, res) => {
    const { amount } = req.body;

    console.log('Request received:', req.body);

    const payload = {
        data: {
            attributes: {
                amount: amount, // Amount is already in cents from Flutter
                currency: 'PHP',
                payment_method_types: ['gcash'],
            },
        },
    };

    console.log('Sending payload to PayMongo:', payload);

    try {
        const response = await axios.post('https://api.paymongo.com/v1/payment_intents', payload, {
            headers: {
                'Authorization': 'Basic ' + Buffer.from(`${process.env.PAYMONGO_API_KEY}:`).toString('base64'),
                'Content-Type': 'application/json',
            },
        });

        res.status(200).json(response.data);
    } catch (error) {
        console.error('Error creating payment intent:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
            res.status(500).json({ error: 'Failed to create payment intent', details: error.response.data });
        } else {
            res.status(500).json({ error: 'Failed to create payment intent', details: error.message });
        }
    }
});

// Test function to verify Axios request to PayMongo
const testPaymentIntent = async () => {
    try {
        const response = await axios.post('https://api.paymongo.com/v1/payment_intents', {
            data: {
                attributes: {
                    amount: 4000, // 40 PHP in cents
                    currency: 'PHP',
                    payment_method_types: ['gcash'],
                },
            },
        }, {
            headers: {
                'Authorization': 'Basic ' + Buffer.from(`${process.env.PAYMONGO_API_KEY}:`).toString('base64'),
                'Content-Type': 'application/json',
            },
        });

        console.log('Response from PayMongo:', response.data);
    } catch (error) {
        console.error('Error:', error.response?.data || error.message);
    }
};

// Call the test function when the server starts
// testPaymentIntent(); // Uncomment this line only when you want to test

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
