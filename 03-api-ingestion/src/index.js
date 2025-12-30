exports.handler = async (event) => {
    console.log("Event received:", JSON.stringify(event));
    return {
        statusCode: 200,
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*", // Required
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        body: JSON.stringify({ message: "Order processed successfully!" }),
    };
};