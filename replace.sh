gleam build

if [[ $? != 0 ]]; then
    exit 1
fi

gleam run -m gleescript


if [[ $? != 0 ]]; then
    exit 1
fi

sudo mv ./graph_lsp /usr/bin/
