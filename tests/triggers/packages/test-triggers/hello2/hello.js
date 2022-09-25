function main(args) {
    let name = args.name || args.fields?.name || 'stranger'
    let greeting = 'Hello ' + name + '!'
    console.log(greeting)
    return {"body": greeting}
}
