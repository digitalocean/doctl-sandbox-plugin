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
// Note:  the "branding" idea as currently implemented in 'nim' is pretty ineffective.
// We end up having to fix up most things on the doctl side anyway.  For the moment,
// we continue to use it but we might consider simplifying it out of existence in favor
// of a clear responsibility on doctl to do the right thing with messages.
const sandboxBranding: Branding = {
  brand: 'DigitalOcean',
  cmdName: 'doctl sandbox',
  defaultHostSuffix: '.doserverless.io', // TODO confirm
  hostPrefix: '', // TODO confirm
  namespaceRepair: "Use 'doctl sandbox [install | connect ]' to create one",
  workbenchURL: '',
  previewWorkbenchURL: ''
}

// Main execution sequence
main().then(flush).catch(handleError)

// Main logic handles everything except cleanup and error handling
async function main() {
  if (process.argv.length < 3) {
    throw new Error('Too few arguments to sandbox exec')
  }
  let command = process.argv[2]
  let args = process.argv.slice(3)
  setBranding(sandboxBranding)
  // Process special "command" which is really a directive not to capture the output.
  // This is to be used by commands that typically run indefinitely in their own console
  // window such as 'project watch' or 'activations logs --watch'.
  if (command === 'nocapture') {
    command = args[0]
    args = args.slice(1)
    return await runNimCommandNoCapture(command, args)
  }
  // The normal path in which output is captured
  const captureLogger = await runNimCommand(command, args)
  const { captured, table, entity, tableColumns, tableOptions, errors } = captureLogger
  // Some errors (particularly in deploy steps) are not thrown by nim and may occur in multiples.
  // These are handled specially here so that doctl has only an error string to deal with similar
  // to errors that are thrown.
  const error = errors?.join('\n')
  // Apply "standard" formatting to table output if any
  let formatted = []
  if (table && table.length > 0) {
    const formatter = new CaptureLogger()                 
    tableOptions.printLine = (line: string) => formatter.log(line)
    cli.table(table, tableColumns, tableOptions)
    formatted = formatter.captured
  }
  const result = { captured, table, formatted, entity, error } 
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
