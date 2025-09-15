const mapBox = require('../services/mapBoxServices');
const polyline = require('@mapbox/polyline');
const routeModel = require('../models/routeModels');

async function getRoute(req, res) {
  try {
    const { start_lat, start_lng, end_lat, end_lng, routeId } = req.body;

    // 1. Call Mapbox
    const route = await mapBox.generateRoute(
      { lat: start_lat, lng: start_lng },
      { lat: end_lat, lng: end_lng }
    );

    // 2. Insert geometry directly
    const updatedRoute = await routeModel.updateRouteGeom(routeId, route.geometry);

    res.json({
      routeId,
      distance: route.distance,
      duration: route.duration,
      geom: updatedRoute.geom
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

module.exports = {
  getRoute
};