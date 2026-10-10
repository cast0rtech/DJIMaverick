/**
 * DJI MAVERICK GCS - INTERACTIVE CONTROLLER & RUNTIME ENGINE
 * Implements Dronelink-like Kinematic Control, Photogrammetry Math & HUD Simulation
 */

document.addEventListener('DOMContentLoaded', () => {
  // --- STATE DEFINITIONS ---
  const state = {
    activeTab: 'panelPreplanning',
    isSimulating: false,
    simProgress: 0.25, // 0 to 1
    simSpeed: 0.0008,
    simTimeTotalSeconds: 1000, // 16m 40s
    activePattern: 'grid',
    terrainFollow: true,
    cameraPresets: {
      m3e: { name: 'Mavic 3E', sensorW: 17.3, focal: 12.3, imgW: 5280, imgH: 3956, aspect: 4/3 },
      m3t: { name: 'Mavic 3T', sensorW: 6.4, focal: 4.5, imgW: 8000, imgH: 6000, aspect: 4/3 },
      m2pro: { name: 'Mavic 2 Pro', sensorW: 13.2, focal: 10.3, imgW: 5472, imgH: 3648, aspect: 3/2 },
      p1: { name: 'Zenmuse P1', sensorW: 35.9, focal: 35.0, imgW: 8192, imgH: 5460, aspect: 3/2 }
    },
    params: {
      altitude: 65,
      frontOverlap: 80,
      sideOverlap: 75,
      cruiseSpeed: 7.5,
      cornerRadius: 12,
      cameraKey: 'm3e',
      areaHa: 14.6
    },
    waypoints: [
      { x: 120, y: 160, alt: 60, type: 'takeoff', label: 'Takeoff' },
      { x: 180, y: 140, alt: 65, type: 'waypoint', label: 'WP1' },
      { x: 260, y: 120, alt: 65, type: 'grid_entry', label: 'Grid In' },
      { x: 580, y: 120, alt: 65, type: 'grid', label: 'G1' },
      { x: 580, y: 170, alt: 65, type: 'grid', label: 'G2' },
      { x: 260, y: 170, alt: 65, type: 'grid', label: 'G3' },
      { x: 260, y: 220, alt: 65, type: 'grid', label: 'G4' },
      { x: 580, y: 220, alt: 65, type: 'grid', label: 'G5' },
      { x: 580, y: 270, alt: 65, type: 'grid', label: 'G6' },
      { x: 260, y: 270, alt: 65, type: 'grid', label: 'G7' },
      { x: 340, y: 340, alt: 60, type: 'orbit_center', label: 'POI Tor' },
      { x: 180, y: 320, alt: 50, type: 'rth', label: 'RTH Entry' }
    ],
    dronePos: { x: 260, y: 170, heading: 45, pitch: -45 },
    radialOpen: false
  };

  // --- DOM ELEMENTS ---
  const navTabs = document.querySelectorAll('.nav-tab');
  const panelViews = document.querySelectorAll('.panel-view');
  
  // Photogrammetry Inputs
  const inputAltitude = document.getElementById('inputFlightAltitude');
  const valAltitude = document.getElementById('valFlightAltitude');
  const inputFrontOverlap = document.getElementById('inputFrontOverlap');
  const valFrontOverlap = document.getElementById('valFrontOverlap');
  const inputSideOverlap = document.getElementById('inputSideOverlap');
  const valSideOverlap = document.getElementById('valSideOverlap');
  const selectCamera = document.getElementById('selectCameraPreset');
  const checkTerrain = document.getElementById('checkTerrainFollow');

  // Computed Metric displays
  const calcGSD = document.getElementById('calcGSD');
  const calcPhotos = document.getElementById('calcPhotos');
  const calcFlightTime = document.getElementById('calcFlightTime');
  const calcArea = document.getElementById('calcArea');

  // Pre-planning Inputs
  const inputCruiseSpeed = document.getElementById('inputCruiseSpeed');
  const valCruiseSpeed = document.getElementById('valCruiseSpeed');
  const inputCornerRadius = document.getElementById('inputCornerRadius');
  const valCornerRadius = document.getElementById('valCornerRadius');

  // Canvases
  const mapCanvas = document.getElementById('flightMapCanvas');
  const mapCtx = mapCanvas.getContext('2d');
  const elevCanvas = document.getElementById('elevationProfileCanvas');
  const elevCtx = elevCanvas.getContext('2d');

  // Radial Menu
  const radialContainer = document.getElementById('radialMenuContainer');
  const radialTrigger = document.getElementById('radialTriggerBtn');

  // Simulation Controls
  const btnPlaySim = document.getElementById('btnPlaySim');
  const btnSimulateMission = document.getElementById('btnSimulateMission');
  const btnExecuteMission = document.getElementById('btnExecuteMission');
  const btnEmergencyHold = document.getElementById('btnEmergencyHold');
  const simProgressFill = document.getElementById('simProgressFill');
  const simTimeElapsed = document.getElementById('simTimeElapsed');
  const simTimeTotal = document.getElementById('simTimeTotal');
  const statDistance = document.getElementById('statDistance');
  const statPhotos = document.getElementById('statPhotos');
  const statArea = document.getElementById('statArea');

  // Virtual Sticks
  const stickDotRight = document.getElementById('stickDotRight');
  const stickDotLeft = document.getElementById('stickDotLeft');

  // FPV & Compass
  const fpvPip = document.getElementById('fpvPip');
  const btnMinPip = document.getElementById('btnMinimizePip');
  const compassNeedle = document.getElementById('compassNeedle');
  const valHeadingDegrees = document.getElementById('valHeadingDegrees');
  const valAltSpeed = document.getElementById('valAltSpeed');
  const valBattery = document.getElementById('valBattery');
  const valBatteryBar = document.getElementById('valBatteryBar');

  // --- 1. TAB ROUTING & NAVIGATION ---
  navTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const targetPanelId = tab.getAttribute('data-target');
      
      navTabs.forEach(t => t.classList.remove('active'));
      panelViews.forEach(p => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPanel = document.getElementById(targetPanelId);
      if (targetPanel) targetPanel.classList.add('active');
      state.activeTab = targetPanelId;
    });
  });

  // Segmented control buttons
  document.querySelectorAll('.segmented-control').forEach(group => {
    group.querySelectorAll('.seg-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        group.querySelectorAll('.seg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        if (btn.dataset.pattern) {
          state.activePattern = btn.dataset.pattern;
          recalculatePhotogrammetry();
        }
      });
    });
  });

  // Component Tree Nodes selection
  document.querySelectorAll('.tree-node').forEach(node => {
    node.addEventListener('click', (e) => {
      e.stopPropagation();
      document.querySelectorAll('.tree-node').forEach(n => n.classList.remove('active'));
      node.classList.add('active');
    });
  });

  // --- 2. PHOTOGRAMMETRY MATH CALCULATION ENGINE ---
  function recalculatePhotogrammetry() {
    const cam = state.cameraPresets[state.params.cameraKey] || state.cameraPresets.m3e;
    const alt = state.params.altitude;
    const fOverlap = state.params.frontOverlap / 100;
    const sOverlap = state.params.sideOverlap / 100;
    const speed = state.params.cruiseSpeed;

    // GSD (Ground Sampling Distance) formula in cm/px:
    // GSD = (SensorWidth_mm * Altitude_m * 100) / (FocalLength_mm * ImageWidth_px)
    const gsd = (cam.sensorW * alt * 100) / (cam.focal * cam.imgW);
    
    // Footprint on ground (meters)
    const groundWidth = (cam.sensorW * alt) / cam.focal;
    const groundHeight = (cam.sensorW / cam.aspect * alt) / cam.focal;

    // Spacing between photos & flight lines
    const photoSpacing = groundHeight * (1 - fOverlap);
    const lineSpacing = groundWidth * (1 - sOverlap);

    // Area in square meters (approx 14.6 ha = 146,000 m²)
    const areaSqMeters = state.params.areaHa * 10000;
    const totalFlightDistance = (areaSqMeters / lineSpacing) * 1.15; // with turns
    
    // Total Photos
    let photosCount = Math.round(totalFlightDistance / Math.max(photoSpacing, 5));
    if (state.activePattern === 'crosshatch') photosCount = Math.round(photosCount * 1.85);

    // Flight time in seconds
    const flightTimeSec = Math.round(totalFlightDistance / speed) + (photosCount * 0.4);
    state.simTimeTotalSeconds = flightTimeSec;

    // Update UI elements
    calcGSD.innerHTML = `${gsd.toFixed(2)} <span class="unit">cm/px</span>`;
    calcPhotos.innerHTML = `${photosCount} <span class="unit">fotos</span>`;
    calcArea.innerHTML = `${state.params.areaHa.toFixed(1)} <span class="unit">ha</span>`;
    
    const minutes = Math.floor(flightTimeSec / 60);
    const seconds = Math.floor(flightTimeSec % 60);
    const timeFormatted = `${minutes}m ${seconds.toString().padStart(2, '0')}s`;
    calcFlightTime.textContent = timeFormatted;
    simTimeTotal.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  // --- 3. EVENT LISTENERS FOR CONTROLS ---
  inputAltitude.addEventListener('input', (e) => {
    state.params.altitude = parseFloat(e.target.value);
    valAltitude.textContent = `${state.params.altitude} m`;
    recalculatePhotogrammetry();
  });

  inputFrontOverlap.addEventListener('input', (e) => {
    state.params.frontOverlap = parseInt(e.target.value);
    valFrontOverlap.textContent = `${state.params.frontOverlap}%`;
    recalculatePhotogrammetry();
  });

  inputSideOverlap.addEventListener('input', (e) => {
    state.params.sideOverlap = parseInt(e.target.value);
    valSideOverlap.textContent = `${state.params.sideOverlap}%`;
    recalculatePhotogrammetry();
  });

  inputCruiseSpeed.addEventListener('input', (e) => {
    state.params.cruiseSpeed = parseFloat(e.target.value);
    valCruiseSpeed.textContent = `${state.params.cruiseSpeed.toFixed(1)} m/s`;
    recalculatePhotogrammetry();
  });

  inputCornerRadius.addEventListener('input', (e) => {
    state.params.cornerRadius = parseInt(e.target.value);
    valCornerRadius.textContent = `${state.params.cornerRadius}.0 m`;
  });

  selectCamera.addEventListener('change', (e) => {
    state.params.cameraKey = e.target.value;
    recalculatePhotogrammetry();
  });

  checkTerrain.addEventListener('change', (e) => {
    state.terrainFollow = e.target.checked;
  });

  // Radial Menu Toggle
  radialTrigger.addEventListener('click', () => {
    state.radialOpen = !state.radialOpen;
    radialContainer.classList.toggle('open', state.radialOpen);
  });

  document.querySelectorAll('.radial-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const title = btn.getAttribute('title');
      triggerNotification(`Herramienta activada: ${title}`);
      radialContainer.classList.remove('open');
      state.radialOpen = false;
    });
  });

  // Minimize PIP
  btnMinPip.addEventListener('click', () => {
    fpvPip.classList.toggle('minimized');
    btnMinPip.innerHTML = fpvPip.classList.contains('minimized') ? '+' : '&minus;';
  });

  // Map Layer Pill buttons
  document.querySelectorAll('.glass-pill-menu .pill-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.glass-pill-menu .pill-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Notifications toast helper
  function triggerNotification(text) {
    const toast = document.createElement('div');
    toast.style.position = 'fixed';
    toast.style.bottom = '80px';
    toast.style.left = '50%';
    toast.style.transform = 'translateX(-50%)';
    toast.style.background = 'rgba(14, 20, 32, 0.95)';
    toast.style.border = '1px solid #00f0ff';
    toast.style.color = '#00f0ff';
    toast.style.padding = '8px 18px';
    toast.style.borderRadius = '9999px';
    toast.style.fontFamily = 'Outfit, sans-serif';
    toast.style.fontSize = '12px';
    toast.style.fontWeight = '600';
    toast.style.boxShadow = '0 0 20px rgba(0, 240, 255, 0.4)';
    toast.style.zIndex = '999';
    toast.textContent = text;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 2600);
  }

  // --- 4. SIMULATION PLAYBACK & SCRUBBER ---
  function toggleSimulation() {
    state.isSimulating = !state.isSimulating;
    btnPlaySim.innerHTML = state.isSimulating
      ? `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect></svg>`
      : `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>`;
    
    if (state.isSimulating) {
      triggerNotification('Bucle Cinemático Virtual Sticks Iniciado @ 10 Hz');
    }
  }

  btnPlaySim.addEventListener('click', toggleSimulation);
  btnSimulateMission.addEventListener('click', () => {
    state.simProgress = 0;
    if (!state.isSimulating) toggleSimulation();
  });

  btnExecuteMission.addEventListener('click', () => {
    triggerNotification('Misión Cargada & Enganche Virtual Sticks ACTIVO');
    if (!state.isSimulating) toggleSimulation();
  });

  btnEmergencyHold.addEventListener('click', () => {
    state.isSimulating = false;
    btnPlaySim.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>`;
    triggerNotification('EMERGENCY HOLD ACTIVADO: Aeronave estacionaria en Hovering');
  });

  // Timeline Scrubber click
  const timelineTrack = document.getElementById('simTimelineTrack');
  timelineTrack.addEventListener('click', (e) => {
    const rect = timelineTrack.getBoundingClientRect();
    const clickRatio = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    state.simProgress = clickRatio;
    updateSimulationState(0);
  });

  // --- 5. TACTICAL CANVAS MAP RENDERER ---
  function resizeCanvases() {
    const viewportRect = mapCanvas.parentElement.getBoundingClientRect();
    mapCanvas.width = viewportRect.width;
    mapCanvas.height = viewportRect.height;

    const elevRect = elevCanvas.parentElement.getBoundingClientRect();
    elevCanvas.width = elevRect.width;
    elevCanvas.height = elevRect.height;
  }
  window.addEventListener('resize', resizeCanvases);
  resizeCanvases();

  // Catmull-Rom or Bezier spline interpolation
  function getPointAlongPath(t) {
    const pts = state.waypoints;
    const totalSegments = pts.length - 1;
    const scaledT = t * totalSegments;
    const index = Math.min(Math.floor(scaledT), totalSegments - 1);
    const subT = scaledT - index;

    const p0 = pts[index];
    const p1 = pts[index + 1];

    const x = p0.x + (p1.x - p0.x) * subT;
    const y = p0.y + (p1.y - p0.y) * subT;

    const dx = p1.x - p0.x;
    const dy = p1.y - p0.y;
    const heading = Math.atan2(dy, dx) * (180 / Math.PI);

    return { x, y, heading };
  }

  function renderTacticalMap() {
    const w = mapCanvas.width;
    const h = mapCanvas.height;
    mapCtx.clearRect(0, 0, w, h);

    // 1. Satellite Base Grid Pattern
    mapCtx.fillStyle = '#06090e';
    mapCtx.fillRect(0, 0, w, h);

    // Decorative topographic contour curves
    mapCtx.strokeStyle = 'rgba(0, 240, 255, 0.04)';
    mapCtx.lineWidth = 1;
    for (let r = 80; r < Math.max(w, h); r += 90) {
      mapCtx.beginPath();
      mapCtx.ellipse(w * 0.45, h * 0.48, r, r * 0.65, 0.25, 0, Math.PI * 2);
      mapCtx.stroke();
    }

    // Secondary sub-grid
    mapCtx.strokeStyle = 'rgba(255, 255, 255, 0.025)';
    mapCtx.lineWidth = 1;
    const step = 40;
    for (let x = 0; x < w; x += step) {
      mapCtx.beginPath();
      mapCtx.moveTo(x, 0);
      mapCtx.lineTo(x, h);
      mapCtx.stroke();
    }
    for (let y = 0; y < h; y += step) {
      mapCtx.beginPath();
      mapCtx.moveTo(0, y);
      mapCtx.lineTo(w, y);
      mapCtx.stroke();
    }

    // 2. Photogrammetry Polygon Fill (Survey Area)
    mapCtx.fillStyle = 'rgba(0, 240, 255, 0.05)';
    mapCtx.strokeStyle = 'rgba(0, 240, 255, 0.4)';
    mapCtx.lineWidth = 1.5;
    mapCtx.setLineDash([6, 4]);

    mapCtx.beginPath();
    mapCtx.moveTo(240, 100);
    mapCtx.lineTo(600, 100);
    mapCtx.lineTo(600, 300);
    mapCtx.lineTo(240, 300);
    mapCtx.closePath();
    mapCtx.fill();
    mapCtx.stroke();
    mapCtx.setLineDash([]); // Reset dash

    // Survey Polygon Label
    mapCtx.fillStyle = 'rgba(0, 240, 255, 0.7)';
    mapCtx.font = '600 10px JetBrains Mono';
    mapCtx.fillText('POLÍGONO FOTOGRAMÉTRICO [14.6 ha]', 250, 92);

    // 3. Flight Path Line (Curved Spline)
    mapCtx.strokeStyle = 'rgba(0, 240, 255, 0.85)';
    mapCtx.lineWidth = 2.5;
    mapCtx.shadowColor = 'rgba(0, 240, 255, 0.5)';
    mapCtx.shadowBlur = 10;

    mapCtx.beginPath();
    state.waypoints.forEach((wp, idx) => {
      if (idx === 0) mapCtx.moveTo(wp.x, wp.y);
      else mapCtx.lineTo(wp.x, wp.y);
    });
    mapCtx.stroke();
    mapCtx.shadowBlur = 0; // Reset shadow

    // 4. Waypoint Nodes & Photo Trigger Flashes
    state.waypoints.forEach((wp, idx) => {
      mapCtx.beginPath();
      mapCtx.arc(wp.x, wp.y, 4.5, 0, Math.PI * 2);
      mapCtx.fillStyle = wp.type === 'takeoff' ? '#00e676' : (wp.type === 'orbit_center' ? '#ffab00' : '#00f0ff');
      mapCtx.fill();
      mapCtx.lineWidth = 1.5;
      mapCtx.strokeStyle = '#fff';
      mapCtx.stroke();

      // Waypoint Label
      mapCtx.fillStyle = 'rgba(255, 255, 255, 0.85)';
      mapCtx.font = '500 9px JetBrains Mono';
      mapCtx.fillText(wp.label, wp.x + 8, wp.y - 6);
    });

    // 5. POI Focus Tether & Marker
    const poi = { x: 420, y: 200 };
    mapCtx.beginPath();
    mapCtx.arc(poi.x, poi.y, 8, 0, Math.PI * 2);
    mapCtx.fillStyle = 'rgba(157, 78, 221, 0.3)';
    mapCtx.fill();
    mapCtx.strokeStyle = '#9d4edd';
    mapCtx.lineWidth = 2;
    mapCtx.stroke();

    // POI Crosshair
    mapCtx.beginPath();
    mapCtx.moveTo(poi.x - 12, poi.y);
    mapCtx.lineTo(poi.x + 12, poi.y);
    mapCtx.moveTo(poi.x, poi.y - 12);
    mapCtx.lineTo(poi.x, poi.y + 12);
    mapCtx.strokeStyle = '#9d4edd';
    mapCtx.stroke();
    mapCtx.fillStyle = '#9d4edd';
    mapCtx.font = '700 9px JetBrains Mono';
    mapCtx.fillText('POI #1 (Subestación)', poi.x + 14, poi.y + 4);

    // Tether line from Drone to POI
    mapCtx.setLineDash([3, 4]);
    mapCtx.strokeStyle = 'rgba(157, 78, 221, 0.6)';
    mapCtx.beginPath();
    mapCtx.moveTo(state.dronePos.x, state.dronePos.y);
    mapCtx.lineTo(poi.x, poi.y);
    mapCtx.stroke();
    mapCtx.setLineDash([]);

    // 6. Drone Avatar & Camera Frustum Beam
    drawDroneAvatar(state.dronePos.x, state.dronePos.y, state.dronePos.heading);
  }

  function drawDroneAvatar(x, y, headingDeg) {
    const headingRad = (headingDeg * Math.PI) / 180;
    
    // Camera Field of View (FOV) Frustum Cone
    mapCtx.save();
    mapCtx.translate(x, y);
    mapCtx.rotate(headingRad);

    const fovDist = 55;
    const fovWidth = 35;
    const gradient = mapCtx.createLinearGradient(0, 0, fovDist, 0);
    gradient.addColorStop(0, 'rgba(0, 240, 255, 0.4)');
    gradient.addColorStop(1, 'rgba(0, 240, 255, 0.0)');

    mapCtx.fillStyle = gradient;
    mapCtx.beginPath();
    mapCtx.moveTo(0, 0);
    mapCtx.lineTo(fovDist, -fovWidth / 2);
    mapCtx.lineTo(fovDist, fovWidth / 2);
    mapCtx.closePath();
    mapCtx.fill();

    // Drone Quadcopter Frame
    mapCtx.strokeStyle = '#fff';
    mapCtx.lineWidth = 2;

    // Cross arms
    mapCtx.beginPath();
    mapCtx.moveTo(-9, -9);
    mapCtx.lineTo(9, 9);
    mapCtx.moveTo(-9, 9);
    mapCtx.lineTo(9, -9);
    mapCtx.stroke();

    // Rotors
    mapCtx.fillStyle = '#00f0ff';
    [[-9, -9], [9, 9], [-9, 9], [9, -9]].forEach(([rx, ry]) => {
      mapCtx.beginPath();
      mapCtx.arc(rx, ry, 3.5, 0, Math.PI * 2);
      mapCtx.fill();
    });

    // Central body & heading nose
    mapCtx.fillStyle = '#040914';
    mapCtx.beginPath();
    mapCtx.arc(0, 0, 5, 0, Math.PI * 2);
    mapCtx.fill();
    mapCtx.stroke();

    // Green nose indicator
    mapCtx.fillStyle = '#00e676';
    mapCtx.beginPath();
    mapCtx.moveTo(4, 0);
    mapCtx.lineTo(0, -3);
    mapCtx.lineTo(0, 3);
    mapCtx.closePath();
    mapCtx.fill();

    mapCtx.restore();
  }

  // --- 6. TERRAIN PROFILE RENDERER (DEM / TERRAIN FOLLOW) ---
  function renderElevationProfile() {
    const w = elevCanvas.width;
    const h = elevCanvas.height;
    elevCtx.clearRect(0, 0, w, h);

    // Ground elevation contour (simulated SRTM terrain profile)
    elevCtx.beginPath();
    elevCtx.moveTo(0, h);

    const terrainPoints = [];
    for (let x = 0; x <= w; x += 20) {
      const elev = 35 + Math.sin(x * 0.012) * 12 + Math.cos(x * 0.025) * 8;
      const y = h - elev;
      terrainPoints.push({ x, y, elev });
      elevCtx.lineTo(x, y);
    }
    elevCtx.lineTo(w, h);
    elevCtx.closePath();

    const groundGrad = elevCtx.createLinearGradient(0, 0, 0, h);
    groundGrad.addColorStop(0, 'rgba(80, 60, 40, 0.7)');
    groundGrad.addColorStop(1, 'rgba(25, 18, 12, 0.9)');
    elevCtx.fillStyle = groundGrad;
    elevCtx.fill();

    elevCtx.strokeStyle = 'rgba(255, 171, 0, 0.75)';
    elevCtx.lineWidth = 1.5;
    elevCtx.stroke();

    // Flight Profile Line (constant AGL above terrain)
    elevCtx.beginPath();
    terrainPoints.forEach((pt, idx) => {
      const droneY = pt.y - 25; // 25px = simulated 65m AGL offset
      if (idx === 0) elevCtx.moveTo(pt.x, droneY);
      else elevCtx.lineTo(pt.x, droneY);
    });
    elevCtx.strokeStyle = '#00f0ff';
    elevCtx.lineWidth = 2;
    elevCtx.stroke();

    // Drone position on profile
    const droneProgX = state.simProgress * w;
    const currentTerrainPt = terrainPoints.find(p => p.x >= droneProgX) || terrainPoints[0];
    const droneMarkerY = currentTerrainPt.y - 25;

    elevCtx.fillStyle = '#00f0ff';
    elevCtx.beginPath();
    elevCtx.arc(droneProgX, droneMarkerY, 4, 0, Math.PI * 2);
    elevCtx.fill();

    // AGL indicator ruler line
    elevCtx.strokeStyle = 'rgba(0, 240, 255, 0.5)';
    elevCtx.setLineDash([2, 2]);
    elevCtx.beginPath();
    elevCtx.moveTo(droneProgX, droneMarkerY);
    elevCtx.lineTo(droneProgX, currentTerrainPt.y);
    elevCtx.stroke();
    elevCtx.setLineDash([]);
  }

  // --- 7. MAIN SIMULATION & KINEMATICS UPDATE LOOP ---
  function updateSimulationState(delta) {
    if (state.isSimulating) {
      state.simProgress += state.simSpeed * delta;
      if (state.simProgress > 1) {
        state.simProgress = 0;
      }
    }

    // Update Interpolated Drone Position
    const pathPt = getPointAlongPath(state.simProgress);
    state.dronePos.x = pathPt.x;
    state.dronePos.y = pathPt.y;
    state.dronePos.heading = pathPt.heading;

    // Update Bottom Scrubber & Stats
    simProgressFill.style.width = `${(state.simProgress * 100).toFixed(1)}%`;

    const currentElapsed = Math.floor(state.simProgress * state.simTimeTotalSeconds);
    const m = Math.floor(currentElapsed / 60);
    const s = currentElapsed % 60;
    simTimeElapsed.textContent = `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;

    const totalDist = 3420;
    const curDist = Math.floor(state.simProgress * totalDist);
    statDistance.textContent = `${curDist}m / ${totalDist}m`;

    const totalPhotosCount = 312;
    const curPhotos = Math.floor(state.simProgress * totalPhotosCount);
    statPhotos.textContent = `${curPhotos} / ${totalPhotosCount}`;

    const curArea = (state.simProgress * state.params.areaHa).toFixed(1);
    statArea.textContent = `${curArea} / ${state.params.areaHa} ha`;

    // Compass and Heading Readouts
    compassNeedle.style.transform = `rotate(${pathPt.heading.toFixed(0)}deg)`;
    valHeadingDegrees.textContent = `${pathPt.heading.toFixed(0).padStart(3, '0')}°`;

    // Virtual Sticks Kinematics Animation
    const pitchStickY = Math.sin(state.simProgress * 18) * 16 - 8;
    const rollStickX = Math.cos(state.simProgress * 24) * 14;
    stickDotRight.style.transform = `translate(${rollStickX}px, ${pitchStickY}px)`;

    const yawRate = Math.sin(state.simProgress * 30) * 12;
    stickDotLeft.style.transform = `translate(${yawRate}px, -4px)`;

    // Simulated Battery Depletion
    const batteryRemaining = Math.max(20, Math.floor(86 - state.simProgress * 28));
    valBattery.innerHTML = `${batteryRemaining}% &bull; 22.8V (${Math.round(batteryRemaining * 0.3)} min)`;
    valBatteryBar.style.width = `${batteryRemaining}%`;
  }

  let lastTime = performance.now();
  function animationFrame(now) {
    const delta = (now - lastTime) / 16.66; // Normalized to 60fps
    lastTime = now;

    updateSimulationState(delta);
    renderTacticalMap();
    renderElevationProfile();

    requestAnimationFrame(animationFrame);
  }

  // Initial calculation and launch animation
  recalculatePhotogrammetry();
  requestAnimationFrame(animationFrame);
});
