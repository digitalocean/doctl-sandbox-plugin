#!/usr/bin/env node
/*
 * DigitalOcean, LLC CONFIDENTIAL
 * ------------------------------
 *
 *   2021 - present DigitalOcean, LLC
 *   All Rights Reserved.
 *
 * NOTICE:
 *
 * All information contained herein is, and remains the property of
 * DigitalOcean, LLC and its suppliers, if any.  The intellectual and technical
 * concepts contained herein are proprietary to DigitalOcean, LLC and its
 * suppliers and may be covered by U.S. and Foreign Patents, patents
 * in process, and are protected by trade secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from DigitalOcean, LLC.
 */

// Utility to generate the Cobra compatible wrappers in golang to dispatch to nim ('sandbox')
// commands.

const fs = require('fs')

// Special case tables.   These are things that would require code introspection to learn because oclif does not put them in the
// manifest.

// The oclif.manifest generator leaves out 'multiple'
const multiples = {
     'action:create': [ 'annotation', 'param', 'env'],
     'action:update': [ 'annotation', 'param', 'env'],
     'action:invoke': [ 'param' ],
     'package:bind': [ 'annotation', 'param' ],
     'package:create': [ 'annotation', 'param' ],
     'package:update': [ 'annotation', 'param' ],
     'trigger:create': [ 'annotation', 'param' ],
     'trigger:fire': [ 'param' ],
     'trigger:update': [ 'annotation', 'param' ]
}

// The manifest also omits the strict/non-strict distinction.  Most parsing is strict so this only affects a few commands.
const nonStrict = [
     'project:deploy',
     'auth:logout'
]

// Flags that duplicate doctl global flags with the same meaning should be skipped
// Flags that have a different meaning are "ok" (but will hide global ones).  Doctl
// doesn't have a version flag but it has a version command.  The flag would be confusing.
const skipFlags = ["help", "verbose", "version"]

// Avoid any shortcuts that conflict with global ones
const skipShortcuts = [ "t", "u", "c", "o", "h", "v" ]

// The copyright comment, + package and import statements, that start every file
const headMatter = `/*
Copyright 2018 The Doctl Authors All rights reserved.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package commands

import (
    "github.com/digitalocean/doctl"
    "github.com/spf13/cobra"
)
`

// The core generate function (everything except I/O and final assembly of lines)
function generate(commands, topic, subtree, sec1, sec2) {
  escapeDescriptions(commands)
  fixupOclifManifest(commands)
  sec1.push(`func ${camelize(subtree)}() *Command {`)
  sec1.push('    cmd := &Command{')
  sec1.push('        Command: &cobra.Command{')
  sec1.push(`            Use: "${subtree}",`)  
  sec1.push(`            Short: "This is the ${subtree} subtree",`)
  sec1.push('            Long: `This is more information about the ' + subtree + ' subtree`,')
  sec1.push('        },')
  sec1.push('    }')
  sec1.push('')
  const topicKey = topic + ':'
  for (const cmd in commands) {
    if (cmd.startsWith(topicKey)) {
      addCommand(topic, subtree, cmd.slice(topicKey.length), commands[cmd], sec1, sec2)
    }
  }
  sec1.push('    return cmd')
  sec1.push('}')
}

// Subroutine to add the material for one command
function addCommand(topic, subtree, command, metadata, sec1, sec2) {
  const capCcmd = camelize(command)
  const ccmd = decapitalize(capCcmd)
  const runnerName = 'Run' + camelize(subtree) + capCcmd

  // Add the definition of the command to the head section
  const use = generateUse(command, metadata.args)
  const short = metadata.description
  const long = `More information about '${subtree} ${command}'`
  sec1.push(`    ${ccmd} := cmdBuilderWithInit(cmd, ${runnerName}, "${use}", "${short}",`)
  sec1.push('        `' + long + '`,')
  sec1.push('        Writer, false)')

  // Add flags
  const booleanFlags = []
  const stringFlags = []
  for (flag in metadata.flags) {
    if (!skipFlags.includes(flag)) {
      generateFlag(ccmd, metadata.flags[flag], booleanFlags, stringFlags, sec1)
    }
  }
  sec1.push('')
  
  // Convert the flags arguments to their codegenned golang representation
  const bflags = codegenStringArray(booleanFlags)
  const sflags = codegenStringArray(stringFlags)
    
  // Add the runner to the command section
  sec2.push(`func ${runnerName}(c *CmdConfig) error {`)
  if (!metadata.nonStrict) {
    generateArgsCheck(metadata.args, sec2)
  }
  sec2.push(`    output, err := RunSandboxExec("${topic}/${command}", c, ${bflags}, ${sflags})`)
  sec2.push('    if err != nil {')
  sec2.push('        return err')
  sec2.push('    }')
  sec2.push('    PrintSandboxTextOutput(output)')
  sec2.push('    return nil')
  sec2.push('}')
  sec2.push('')
}

// Converts a string array to a string representation of the same array in golang
function codegenStringArray(array) {
  array = array.map(item => `"${item}"`)
  return '[]string{' + array.join(',') + '}'
} 

// Escape double quotes in the description members of a map (topics, commands, command flags, command args)
function escapeDescriptions(tofix) {
     for (const member in tofix) {
          const desc = tofix[member].description
          if (desc) {
               tofix[member].description = desc.replace(/"/g, '\\"').replace(/\n/g, '\\n')
          }
          const flags = tofix[member].flags
          if (flags) {
               escapeDescriptions(flags)
          }
          const args = tofix[member].args
          if (args) {
               escapeDescriptions(args)
          }
     }
}

// Perform special fixups of commands structure.  We should try to minimize the amount of this that we do.
function fixupOclifManifest(commands) {
     // Indicate flags that take multiple values
     for (const cmd in multiples) {
          const flags = commands[cmd].flags
          for (const flag of multiples[cmd]) {
               flags[flag].multiple = true
          }
     }
     // Indicate commands where parsing is non-strict (the default is strict)
     for (cmd of nonStrict) {
          commands[cmd].nonStrict = true
     }
}

// Capitalize a word
function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.substring(1)
}

// Decapitalize a word
function decapitalize(word) {
  return word.charAt(0).toLowerCase() + word.substring(1)
}

// Make a word that might contain dashes into a capitalized camel case word that doesn't
// contain dashes
function camelize(word) {
  const words = word.split('-').map(capitalize)
  return words.join('')  
}

// Subroutine to generate a use tag from command name and args
function generateUse(command, args) {
  let ans = command
  for (const arg of args) {
    ans = ans + ' ' + generateArg(arg)
  }
  return ans
}

// Subroutine to generate the conventional usage syntax for an argument
// Handles required vs optional.  TODO follow cobra guidelines more exactly. 
function generateArg(arg) {
  if (arg.required) {
    return '<' + arg.name + '>'
  } else {
    return '[<' + arg.name + '>]'
  }
}

// Subroutine to generate a cobra flag definition from an oclif one
function generateFlag(command, meta, booleanFlags, stringFlags, out) {
  const {type, name, required, char, hidden, description } = meta
  let deflt = meta['default'] // avoid confusion with 'default' keyword
  // Oclif manifest flag types lump numbers and strings together.  We can distinguish if there
  // is a default value, but otherwise it is ambiguous.  We assume string in that case (more common).
  let funcName
  if (type === 'boolean') {
    funcName = 'AddBoolFlag'
    deflt = deflt || false
    booleanFlags.push(name)
  } else if (typeof deflt === 'number') {
    funcName = 'AddIntFlag'
    deflt = deflt || 0
    stringFlags.push(name)
  } else {
    funcName = 'AddStringFlag'
    deflt = `"${deflt || ''}"`
    stringFlags.push(name)
  }
  const short = skipShortcuts.includes(char) ? '' : char || ''
  const req = required ? ', requiredOpt()' : ''  
  out.push(`    ${funcName}(${command}, "${name}", "${short}", ${deflt}, "${description}"${req})`)
  if (hidden) {
    out.push(`    ${command}.Flags().MarkHidden("${name}")`)   
  }
}

// Subroutine to generate a check on the number of args
function generateArgsCheck(metaArgs, sec2) {
  let min = 0, max = 0
  for (arg of metaArgs) {
    max++
    if (arg.required) {
      min++      
    }        
  }
  if (min == 1 && max == 1) {
    // Exploit common case of exactly one arg by using provided utility
    sec2.push('    err := ensureOneArg(c)')
    sec2.push('    if err != nil {')
    sec2.push('        return err')
    sec2.push('    }')
    return
  }
  // General case: either one or two checks depending on min
  sec2.push('    argCount := len(c.Args)')
  if (min > 0) {
    sec2.push(`    if argCount < ${min} {`)
    sec2.push('        return doctl.NewMissingArgsErr(c.NS)')
    sec2.push('    }')
  }
  sec2.push(`    if argCount > ${max} {`)
  sec2.push('        return doctl.NewTooManyArgsErr(c.NS)')
  sec2.push('    }')
} 

// Main logic
// Arguments are
//   path to oclif manifest
//   nim topic to process (e.g. 'action')
//   doctl subtree name that corresponds (the output file will be that name + .go)
if (process.argv.length != 5) {
     console.error("wrong number of arguments")
     process.exit()
}
const manifestFile = process.argv[2]
const topic = process.argv[3]
const subtree = process.argv[4]
const outfile = subtree + '.go'
const manifestText = fs.readFileSync(manifestFile)
const manifestJSON = JSON.parse(manifestText)
const sec1 = headMatter.split('\n')
const sec2 = []
generate(manifestJSON.commands, topic, subtree, sec1, sec2)
const output = sec1.concat(sec2).join('\n')
fs.writeFileSync(outfile, output)
