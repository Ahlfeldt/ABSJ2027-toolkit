const PYODIDE_VERSION = '0.28.3';
const PYODIDE_BASE = `https://cdn.jsdelivr.net/pyodide/v${PYODIDE_VERSION}/full/`;
const MODULES = [
  'status.py', 'numerics.py', 'create_city.py', 'solver.py', 'eqfind.py',
  'find_utilde.py', 'validate_inputs.py', 'pack_result.py',
  'is_paper_parameters.py', 'quantify_city.py', 'apply_changes.py',
  'web_simulation.py'
];

let ready;
async function initialize() {
  postMessage({type: 'status', message: 'Loading the Python scientific runtime…'});
  importScripts(`${PYODIDE_BASE}pyodide.js`);
  const pyodide = await loadPyodide({indexURL: PYODIDE_BASE});
  await pyodide.loadPackage(['numpy', 'scipy']);
  postMessage({type: 'status', message: 'Loading the ABSJ2027 model…'});
  const modelBase = new URL('../Python/functions/', self.location.href);
  await Promise.all(MODULES.map(async name => {
    const response = await fetch(new URL(name, modelBase));
    if (!response.ok) throw new Error(`Could not load ${name}.`);
    pyodide.FS.writeFile(`/home/pyodide/${name}`, await response.text(), {encoding: 'utf8'});
  }));
  pyodide.runPython("import sys; sys.path.insert(0, '/home/pyodide'); from web_simulation import simulate_web");
  postMessage({type: 'ready'});
  return pyodide;
}

ready = initialize().catch(error => {
  postMessage({type: 'error', message: `The simulator could not start: ${error.message}`});
  throw error;
});

self.onmessage = async event => {
  if (event.data?.type !== 'simulate') return;
  try {
    const pyodide = await ready;
    postMessage({type: 'status', message: 'Quantifying the baseline city…'});
    pyodide.globals.set('simulation_payload_json', JSON.stringify(event.data.payload));
    const output = await pyodide.runPythonAsync(`
import json
simulation_result_json = json.dumps(simulate_web(json.loads(simulation_payload_json)), allow_nan=False)
simulation_result_json
`);
    postMessage({type: 'result', result: JSON.parse(output)});
  } catch (error) {
    postMessage({type: 'error', message: error.message || String(error)});
  }
};
