#!/usr/bin/env node

/**
 * Production Deployment Verification Script
 * 
 * Verifies that the axios dependency issue has been resolved
 * and all critical modules can load properly.
 */

console.log('🔍 PRODUCTION DEPLOYMENT VERIFICATION');
console.log('=====================================');
console.log(`Date: ${new Date().toISOString()}`);
console.log(`Node Version: ${process.version}`);
console.log('');

let hasError = false;

// Test 1: Verify axios can be imported
console.log('1. Testing axios import...');
try {
  const axios = require('axios');
  console.log('   ✅ axios imported successfully');
  console.log(`   ✅ axios version: ${axios.VERSION || 'version not available'}`);
} catch (error) {
  console.log('   ❌ FAILED to import axios');
  console.log(`   ❌ Error: ${error.message}`);
  hasError = true;
}

// Test 2: Verify aiIdentityService can be loaded
console.log('');
console.log('2. Testing aiIdentityService import...');
try {
  const aiService = require('../dist/services/aiIdentityService');
  console.log('   ✅ aiIdentityService loaded successfully');
} catch (error) {
  console.log('   ❌ FAILED to load aiIdentityService');
  console.log(`   ❌ Error: ${error.message}`);
  hasError = true;
}

// Test 3: Verify main application can start
console.log('');
console.log('3. Testing main application modules...');
try {
  // Test critical imports without actually starting the server
  require('../dist/routes/index');
  console.log('   ✅ Routes loaded successfully');
  
  require('../dist/modules/users/users.controller');
  console.log('   ✅ Users controller loaded successfully');
} catch (error) {
  console.log('   ❌ FAILED to load application modules');
  console.log(`   ❌ Error: ${error.message}`);
  hasError = true;
}

// Final result
console.log('');
console.log('=====================================');
if (hasError) {
  console.log('❌ VERIFICATION FAILED');
  console.log('   The application still has dependency issues.');
  console.log('   Please check the error messages above.');
  process.exit(1);
} else {
  console.log('✅ VERIFICATION PASSED');
  console.log('   All critical dependencies are available.');
  console.log('   The application should start without errors.');
  console.log('   🚀 Ready for production!');
  process.exit(0);
}