const express = require('express');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const STORAGE_SERVICE_URL = process.env.STORAGE_URL || 'http://storage:5000';
const VOLUME_STORAGE_PATH = '/app/vstorage/vstorage';

// Middleware
app.use(express.text());

function createErrorResponse(message, statusCode = 500) {
    return { message, statusCode };
}

async function makeHttpRequest(method, url, options = {}) {
    try {
        const response = await fetch(url, {
            method,
            ...options
        });

        if (!response.ok) {
            throw new Error(`HTTP ${method} ${url} failed: ${response.status}`);
        }

        return response;
    } catch (error) {
        console.error(`HTTP request failed: ${method} ${url} -`, error);
        throw error;
    }
}

function getSystemInfo() {
    // Get uptime in hours
    const uptimeSeconds = os.uptime();
    const uptimeHours = Math.round((uptimeSeconds / 3600) * 100) / 100;

    // Get free disk space in MB using df command (similar to Python's shutil.disk_usage)
    let freeDiskMB = 0;
    try {
        const dfOutput = execSync('df / | tail -1', { encoding: 'utf8' });
        const parts = dfOutput.trim().split(/\s+/);
        // df output format: Filesystem 1K-blocks Used Available Use% Mounted-on
        // Available is in 1K blocks, convert to MB
        freeDiskMB = Math.round((parseInt(parts[3]) * 1024) / (1024 * 1024) * 100) / 100;
    } catch (error) {
        console.error('Error getting disk usage:', error);
        freeDiskMB = 0;
    }

    // Create timestamp in ISO 8601 format
    const timestamp = new Date().toISOString();

    return `${timestamp}: uptime ${uptimeHours} hours, free disk in root: ${freeDiskMB} Mbytes`;
}

function persistRecord(record) {
    try {
        fs.appendFileSync(VOLUME_STORAGE_PATH, record + '\n');
    } catch (error) {
        console.error('Error writing to volume storage:', error);
    }
}

async function submitRecord(record) {
    try {
        await makeHttpRequest('POST', `${STORAGE_SERVICE_URL}/log`, {
            headers: {
                'Content-Type': 'text/plain'
            },
            body: record
        });
    } catch (error) {
        console.error('Error submitting to storage service:', error);
    }
}

app.get('/status', async (req, res) => {
    try {
        // 5. Analyze local system status
        const systemInfo = getSystemInfo();

        // 6. Submit record to storage service
        await submitRecord(systemInfo);

        // 7. Persist record to volume storage
        persistRecord(systemInfo);

        // 8. Send record as response
        res.set('Content-Type', 'text/plain');
        res.send(systemInfo);

    } catch (error) {
        console.error('Error in /status endpoint:', error);
        res.status(500).send(`Error: ${error.message}`);
    }
});

app.get('/health', (req, res) => {
    res.send('OK');
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).send('Internal Server Error');
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Service2 running on port ${PORT}`);

    // Ensure volume storage file is fresh (start with empty file)
    try {
        const dir = path.dirname(VOLUME_STORAGE_PATH);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        // Always start with a fresh file, similar to storage service
        fs.writeFileSync(VOLUME_STORAGE_PATH, '');
    } catch (error) {
        console.error('Error setting up volume storage:', error);
    }
});
