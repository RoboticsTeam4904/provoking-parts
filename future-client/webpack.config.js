const merge = require("webpack-merge");

const baseConfig = require("./webpack.common");

const production = process.env.NODE_ENV === "production";
const config = production ? require("./webpack.prod") : require("./webpack.dev");

module.exports = merge.smart(baseConfig, config);
