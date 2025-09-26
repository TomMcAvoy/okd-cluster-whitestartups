import { FreeDDNSManager } from './free-ddns-manager';
import { existsSync, readFileSync } from 'fs';

interface DDNSConfig {
  localDomain: string;
  hubIP: string;
  externalDomain?: string;
  debug?: boolean;
  aggressiveScan?: boolean;
  monitoring?: {
    scanInterval?: number;
    logLevel?: string;
  };
}

async function loadConfig(): Promise<DDNSConfig> {
  const configPath = 'config/ddns-config.json';
  
  if (existsSync(configPath)) {
    try {
      const config = JSON.parse(readFileSync(configPath, 'utf8'));
      console.log('📋 Loaded configuration from config/ddns-config.json');
      return config;
    } catch (error) {
      console.warn('⚠️  Could not parse config file, using defaults');
    }
  }

  // Default configuration
  const defaultConfig: DDNSConfig = {
    localDomain: 'home.local',
    hubIP: process.env.ROUTER_IP || '192.168.2.1',
    externalDomain: process.env.EXTERNAL_DOMAIN,
    debug: process.env.DEBUG === 'true',
    aggressiveScan: process.env.AGGRESSIVE_SCAN === 'true',
    monitoring: {
      scanInterval: 120,
      logLevel: 'info'
    }
  };

  console.log('🔧 Using default configuration');
  console.log(`   Local domain: ${defaultConfig.localDomain}`);
  console.log(`   Router IP: ${defaultConfig.hubIP}`);
  
  return defaultConfig;
}

async function main(): Promise<void> {
  try {
    console.log('🆓 OKD Cluster Free DDNS Manager');
    console.log('💰 Total cost: $0.00');
    console.log('🏠 For Bell Hub 3000 + Mac devices');
    console.log('');

    const config = await loadConfig();
    
    const ddnsManager = new FreeDDNSManager({
      localDomain: config.localDomain,
      hubIP: config.hubIP,
      externalDomain: config.externalDomain,
      debug: config.debug,
      aggressiveScan: config.aggressiveScan
    });

    // Handle graceful shutdown
    process.on('SIGINT', () => {
      console.log('\n🛑 Shutting down DDNS monitoring...');
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      console.log('\n🛑 Shutting down DDNS monitoring...');
      process.exit(0);
    });

    await ddnsManager.startFreeMonitoring();

  } catch (error) {
    console.error('❌ DDNS service failed to start:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { FreeDDNSManager };
export type { DDNSConfig };