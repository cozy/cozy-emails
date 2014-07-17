# See documentation on https://github.com/frankrousseau/americano-cozy/#models

americano = require 'americano'

module.exports = TemplateModel = americano.getModel 'Template',
    title: String
    content: String
