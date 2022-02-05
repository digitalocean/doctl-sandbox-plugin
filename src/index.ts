// DigitalOcean, LLC CONFIDENTIAL
// ------------------------------
//
//   2021 - present DigitalOcean, LLC
//   All Rights Reserved.
//
// NOTICE:
//
// All information contained herein is, and remains the property of
// DigitalOcean, LLC and its suppliers, if any.  The intellectual and technical
// concepts contained herein are proprietary to DigitalOcean, LLC and its
// suppliers and may be covered by U.S. and Foreign Patents, patents
// in process, and are protected by trade secret or copyright law.
//
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DigitalOcean, LLC

import { runNimCommand, runNimCommandNoCapture, CaptureLogger, Branding, setBranding } from '@nimbella/nimbella-cli' 
import { ux, cli } from 'cli-ux'

// The current branding plan for this inclusion
const sandboxBranding: Branding = {
  brand: 'DigitalOcean',
  cmdName: 'doctl sandbox',
  defaultHostSuffix: '.doserverless.io', // TODO confirm
  hostPrefix: '', // TODO confirm
  namespaceRepair: "Use 'doctl sandbox [install | connect ]' to create one",
  workbenchURL: '',
  previewWorkbenchURL: ''
}

// The list of commands for which we do not capture the output (the regular command
// output of 'nim' will appear on stdout and can be handled in a streaming fashion).
const noCaptureCommands = [
  'project/watch'  
]

main().then(flush).catch(handleError)

// Main logic handles everything except cleanup and error handling
async function main() {
  if (process.argv.length < 3) {
    throw new Error('Too few arguments to sandbox exec')
  }
  const command = process.argv[2]
  const args = process.argv.slice(3)
  setBranding(sandboxBranding)
  if (noCaptureCommands.includes(command)) {
    return await runNimCommandNoCapture(command, args)
  }
  const captureLogger = await runNimCommand(command, args)
  const { captured, table, entity, tableColumns, tableOptions } = captureLogger
  let formatted = []
  if (table && table.length > 0) {
    const formatter = new CaptureLogger()                 
    tableOptions.printLine = (line: string) => formatter.log(line)
    cli.table(table, tableColumns, tableOptions)
    formatted = formatter.captured
  }
  const result = { captured, table, formatted, entity } 
  console.log(JSON.stringify(result, null, 2))
}

// Ensure that console output is flushed when the command is really finished
async function flush() {
  try {
    await ux.flush()
  } catch {}
}

// Deal with errors thrown from within 'nim'
function handleError(err: any) {
    let msg = err.message
    if (!msg && 'string' === typeof err) {
      msg = err
    }
    console.log(JSON.stringify({ error: msg || 'Unknown error' }, null, 2))
    process.exit(1)
}
