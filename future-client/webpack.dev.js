const path = require("path");

const { NamedModulesPlugin } = require("webpack");

module.exports = {
	mode: "development",
	devtool: "inline-source-map",
	devServer: {
		contentBase: "./dist",
		hot: true
	},
	module: {
		rules: [
			{
        test: /\.scss$/,
        use: [
            "style-loader",
            "css-loader",
            "sass-loader"
        ]
      }
		]
	},
	plugins: [
		new NamedModulesPlugin()
	]
};
