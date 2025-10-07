const axios = require('axios');

const MAPBOX_TOKEN = 'pk.eyJ1Ijoia3lsbHVoaGgiLCJhIjoiY21jNzFrbjhnMWEzdTJqb21razJzMnNzZSJ9.mTR_W24uzbK1y3Z1Y4OjTA'; // Replace with actual Mapbox token

async function generateRoute(start, end, waypoints = []) {

    //Combine all coords
    const allPoints = [start, ...waypoints, end];

    //Convert to lng,lat; format

    const coordsString = allPoints.map(pt => `${pt.lng},${pt.lat}`).join(';');

    //Endpoint URL
    const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${coordsString}?alternatives=true&exclude=toll&geometries=geojson&overview=full&access_token=${MAPBOX_TOKEN}`;
    try {
        const response = await axios.get(url);
        if (response.data.routes && response.data.routes.length > 0) {
            return response.data.routes[0];
        } else {
            throw new Error('No routes found');
        }
    } catch (error) {
        console.error('Error fetching route from Mapbox:', error);
        throw error;
    }
}

async function getNameFromCoordinates(lat, lng) {
    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${MAPBOX_TOKEN}`
    try {
        const response = await axios.get(url)
        if (response.data.features && response.data.features.length > 0) {
            return response.data.features[0].place_name
        } else {
            throw new Error("Name not found")
        }
    } catch (err) {
        console.error('error fetching name', err)
    }
}

module.exports = {
    generateRoute,
    getNameFromCoordinates
};

