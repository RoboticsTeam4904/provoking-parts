const path = require("path");

const MiniCSSExtractPlugin = require("mini-css-extract-plugin");

module.exports = {
	mode: "production",
	devtool: "source-map",
	module: {
		rules: [
			{
        test: /\.scss$/,
        use: [
            MiniCssExtractPlugin.loader,
            "css-loader",
            "sass-loader"
        ]
      }
		]
	},
	plugins: [
		new MiniCssExtractPlugin()
	]
};
